# Before forking anew, kill the unicorn master process that belongs to the
# .oldbin PID. This enables 0 downtime deploys.
class UnicornRelay::Teardown
  def initialize(server:, pid_file:)
    @server   = server
    @pid_file = pid_file
  end

  def perform
    server_has_new_pid_file? && pid and kill_pid
  end

  private

  def kill_pid
    Process.kill(:QUIT, pid)
  rescue Errno::ESRCH
  end

  def server_has_new_pid_file?
    pid_file_exist? && @server.pid != @pid_file
  end

  def pid_file_exist?
    File.exist?(@pid_file)
  end

  def pid_file_content
    File.read(@pid_file)
  rescue Errno::ENOENT, Errno::ENOTDIR
  end

  memoize method:
  def pid
    pid = pid_file_content.to_i
    pid.nonzero?
  end
end
