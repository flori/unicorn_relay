class UnicornRelay::Forker
  class StopException < StandardError; end

  def initialize(script_path: $0, pid_file: nil, argv: ARGV, env: ENV)
    @name             = File.basename(script_path)
    @pid_file         = pid_file
    @argv             = argv
    @env              = env
    @relay_signals    = %i[ HUP USR1 USR2 TTIN TTOU WINCH ]
    @shutdown_signals = {
      :INT  => :INT,
      :QUIT => :QUIT,
      :TERM => :QUIT,
    }
  end

  def start
    handle_old_pid_file
    start_control_loop
  end

  def stop
    stop_control_loop
  end

  private

  def process
    "#@name pid=#$$"
  end

  def output(message)
    STDOUT.puts "#{process} #{message}"
    STDOUT.flush
    self
  end

  def error(message)
    STDERR.puts "#{process} #{message}"
    STDERR.flush
    self
  end

  def read_pid
    File.read(@pid_file).to_i
  end

  def handle_old_pid_file
    unless @pid_file
      output "no pid file was given"
      return
    end
    if pid = read_pid.nonzero?
      Process.kill :INT, pid
      output "interrupts pid=#{pid} from pid file"
    else
      error "ignoring pid file without a pid"
    end
  rescue Errno::ENOENT, Errno::ENOTDIR
    output "no pid file was found at #{@pid_file.inspect}"
    self
  rescue Errno::EPERM
    error "found a pid file for pid=#{pid}, but no permission to signal"
  rescue Errno::ESRCH
    error "found a stale pid file for pid=#{pid}"
  end

  def setup_spawn_env(env)
    if gc = env.delete('UNICORN_GC')
      gc.split(/\s+/).each_with_object(env) do |l, h|
        k, v = l.split('=', 2)
        h[k] = v
      end
    end
    env
  end

  def shutdown_process_group(signal:, shutdown_signal:)
    Signal.trap signal do
      unless @shutdown_signal
        @shutdown_signal = shutdown_signal
        output "received #{signal.inspect}, "\
          "shutting down pgid=#@pgid with #{shutdown_signal.inspect}"
      end
    end
  end

  def relay_to_process_group(signal:)
    # NOTE relaying USR1 signals this way might cause problems when using
    # user/group switching in unicorn
    Signal.trap signal do
      output "relays signal #{signal.inspect} to process group pgid=#@pgid"
      signal_process_group signal
    end
  end

  def install_shutdown_signal_handlers
    @shutdown_signals.each do |signal, shutdown_signal|
      shutdown_process_group signal: signal, shutdown_signal: shutdown_signal
    end
    self
  end

  def install_relay_signal_handlers
    @relay_signals.each do |signal|
      relay_to_process_group signal: signal
    end
    self
  end

  def create_process_group(pid)
    pgid = Process.getpgid(pid)
    Process.detach pid
    pgid
  end

  def fork_child_process_in_pgroup
    # We're passing Ruby GC configuration environment variables through the
    # UNICORN_GC variable indirectly to its spawn instead of defining them in
    # the run script. We don't want to increase *this* process' memory
    # footprint over ca. 22 MiB. Only the unicorn processes themselves should
    # allocate a lot of memory for rails (= several hundred MiB) at startup.
    setup_spawn_env(@env)
    pid  = Process.spawn(@env, @argv.map(&:inspect) * ' ', pgroup: true)
    pgid = create_process_group(pid)
    output "forks child process with pid=#{pid} pgid=#{pgid}"
    pgid
  end

  def signal_process_group(signal)
    Process.kill signal, -@pgid
  end

  def shutdown_signal_pending?
    @shutdown_signal && !@shutdown_signal_sent_at
  end

  # Send shutdown_signal to process group for the first time.
  def send_shutdown_signal
    @shutdown_signal_sent_at = Time.now
    output "Sending #{@shutdown_signal.inspect} to process group pgid=#@pgid"
    signal_process_group @shutdown_signal
  end

  def shutdown_signal_sent_before?
    @shutdown_signal_sent_at && @shutdown_signal_sent_at - Time.now > 60
  end

  # Repeat relaying of all shutdown signals to process group approximately
  # every minute after one was received until every process was shutdown.
  def resend_shutdown_signal
    @shutdown_signal_sent_at = Time.now
    output "Resending #{@shutdown_signal.inspect} to process group pgid=#@pgid"
    signal_process_group @shutdown_signal
  end

  # Exit loop via Errno::ESRCH expception, as soon as process group is
  # empty.
  def check_if_process_group_empty
    signal_process_group 0
  end

  def stop_control_loop
    raise StopException
  end

  def start_control_loop
    @shutdown_signal         = nil
    @shutdown_signal_sent_at = nil

    @pgid = fork_child_process_in_pgroup

    install_shutdown_signal_handlers
    install_relay_signal_handlers

    loop do
      if shutdown_signal_pending?
        send_shutdown_signal
      elsif shutdown_signal_sent_before?
        resend_shutdown_signal
      else
        check_if_process_group_empty
      end
      sleep 1
    end
  rescue Errno::ESRCH
    output "process group pgid=#@pgid empty, exiting"
    return
  rescue StopException
    return
  end
end
