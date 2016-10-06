require 'spec_helper'

describe UnicornRelay::Forker do
  let :server do
    double('Server')
  end

  let :pid_file do
    'foo/bar.pid.oldbin'
  end

  let :forker do
    described_class.new(
      script_path: 'foo/bar/unicorn_relay',
      pid_file:     pid_file
    )
  end

  let :process do
    forker.send(:process)
  end

  describe '#start' do
    it 'calls two other methods' do
      expect(forker).to receive(:handle_old_pid_file)
      expect(forker).to receive(:start_control_loop)
      forker.start
    end
  end

  describe '#stop' do
    it 'calls stop_control_loop' do
      expect(forker).to receive(:stop_control_loop)
      forker.stop
    end
  end

  describe '#process' do
    it 'returns process name and pid' do
      expect(process).to eq "unicorn_relay pid=#$$"
    end
  end

  describe '#output' do
    it 'outputs message to STDOUT and returns self' do
      expect(STDOUT).to receive(:puts).with("#{process} hello")
      expect(forker.send(:output, "hello")).to eq forker
    end
  end

  describe '#error' do
    it 'outputs message to STDERR and returns self' do
      expect(STDERR).to receive(:puts).with("#{process} hello")
      expect(forker.send(:error, "hello")).to eq forker
    end
  end

  describe '#read_pid' do
    it 'returns pid as an Integer' do
      allow(File).to receive(:read).with(pid_file).and_return '666'
      expect(forker.send(:read_pid)).to eq 666
    end
  end

  describe '#handle_old_pid_file' do
    it 'does not have to handle a pid_file' do
      forker = described_class.new
      expect(forker).to receive(:output).with('no pid file was given')
      forker.send(:handle_old_pid_file)
    end

    it 'ignores a pid file without a pid' do
      allow(forker).to receive(:read_pid).and_return 0
      expect(forker).to receive(:error).with('ignoring pid file without a pid')
      forker.send(:handle_old_pid_file)
    end

    it 'ignores a pid file without a pid' do
      allow(forker).to receive(:read_pid).and_return 666
      expect(Process).to receive(:kill).with(:INT, 666)
      expect(forker).to receive(:output).
        with('interrupts pid=666 from pid file')
      forker.send(:handle_old_pid_file)
    end

    it 'handles a missing pid file' do
      allow(forker).to receive(:read_pid).and_raise Errno::ENOENT
      expect(forker).to receive(:output).
        with('no pid file was found at "foo/bar.pid.oldbin"')
      expect(forker.send(:handle_old_pid_file)).to eq forker
    end

    it 'handles insufficient permissions' do
      allow(forker).to receive(:read_pid).and_return 666
      allow(Process).to receive(:kill).and_raise Errno::EPERM
      expect(forker).to receive(:error).
        with("found a pid file for pid=666, but no permission to signal")
      forker.send(:handle_old_pid_file)
    end

    it 'handles stale pid files' do
      allow(forker).to receive(:read_pid).and_return 666
      allow(Process).to receive(:kill).and_raise Errno::ESRCH
      expect(forker).to receive(:error).
        with("found a stale pid file for pid=666")
      forker.send(:handle_old_pid_file)
    end
  end

  describe '#setup_spawn_env' do
    let :env do
      {
        'FOO'        => 'BAR',
        'UNICORN_GC' => 'BAZ=QUUX PI=3.141',
      }
    end

    it 'handles UNICORN_GC env var' do
      expect(forker.send(:setup_spawn_env, env)).to eq(
        'FOO' => 'BAR',
        'BAZ' => 'QUUX',
        'PI'  => '3.141',
      )
    end

    it 'just passes ENV on if UNICORN_GC is not defined' do
      expect(forker.send(:setup_spawn_env, { 'FOO' => 'BAR' })).to eq(
        'FOO' => 'BAR'
      )
    end
  end


  describe '#signal_process_group' do
    it 'sends signal to process group' do
      expect(Process).to receive(:kill).with(:USR1, -666)
      forker.instance_eval do
        @pgid = 666
        signal_process_group(:USR1)
      end
    end
  end

  describe '#shutdown_process_group' do
    it 'installs signal trap' do
      expect(Signal).to receive(:trap).with(:USR1)
      forker.send(:shutdown_process_group, signal: :USR1, shutdown_signal: :USR2)
    end
  end

  describe '#relay_to_process_group' do
    it 'installs signal trap' do
      expect(Signal).to receive(:trap).with(:USR1)
      forker.send(:relay_to_process_group, signal: :USR1)
    end
  end

  describe '#install_shutdown_signal_handlers' do
    it 'installs signal handlers' do
      expect(forker).to receive(:shutdown_process_group).at_least(1)
      forker.send(:install_shutdown_signal_handlers)
    end
  end

  describe '#install_relay_signal_handlers' do
    it 'installs signal handlers' do
      expect(forker).to receive(:relay_to_process_group).at_least(1)
      forker.send(:install_relay_signal_handlers)
    end
  end

  describe '#create_process_group' do
    it 'creates a process group for a pid' do
      expect(Process).to receive(:getpgid).with(666).and_return 667
      expect(Process).to receive(:detach).with(666)
      expect(forker.send(:create_process_group, 666)).to eq 667
    end
  end

  describe '#fork_child_process_in_pgroup' do
    it 'forks and creates a process group' do
      forker = described_class.new(env: {}, argv: [])
      expect(Process).to receive(:spawn).with({}, "", pgroup: true).
        and_return 123
      expect(forker).to receive(:create_process_group).with(123).and_return 456
      expect(forker).to receive(:output).
        with('forks child process with pid=123 pgid=456')
      forker.send(:fork_child_process_in_pgroup)
    end
  end

  context 'shutdown_signal received' do
    before do
      forker.instance_eval do
        @shutdown_signal = :QUIT
        @pgid            = 666
      end
    end

    describe '#send_shutdown_signal' do
      it 'singals process group' do
        expect(forker).to receive(:output).with('Sending :QUIT to process group pgid=666')
        expect(forker).to receive(:signal_process_group).with(:QUIT)
        expect {
          forker.send(:send_shutdown_signal)
        }.to change {
          forker.instance_eval { @shutdown_signal_sent_at }
        }.from(nil).to(instance_of(Time))
      end
    end

    describe '#resend_shutdown_signal' do
      it 'singals process group' do
        forker.instance_eval { @shutdown_signal_sent_at = Time.now }
        expect(forker).to receive(:output).with('Resending :QUIT to process group pgid=666')
        expect(forker).to receive(:signal_process_group).with(:QUIT)
        expect {
          forker.send(:resend_shutdown_signal)
        }.to change {
          forker.instance_eval { @shutdown_signal_sent_at }
        }
      end
    end
  end

  describe '#start_control_loop' do
    it 'runs the control loop' do
      expect(forker).to receive(:fork_child_process_in_pgroup).and_return 666
      expect(forker).to receive(:install_shutdown_signal_handlers)
      expect(forker).to receive(:install_relay_signal_handlers)
      expect(forker).to receive(:loop)
      forker.send(:start_control_loop)
    end

    context 'running the control loop' do
      before do
        allow(forker).to receive(:fork_child_process_in_pgroup).and_return 666
        allow(forker).to receive(:install_shutdown_signal_handlers)
        allow(forker).to receive(:install_relay_signal_handlers)
      end

      it 'sends a shutdown signal if pending' do
        allow(forker).to receive(:output)
        allow(forker).to receive(:shutdown_signal_pending?).and_return true
        allow(forker).to receive(:shutdown_signal_sent_before?).and_return false
        expect(forker).to receive(:send_shutdown_signal).and_raise UnicornRelay::Forker::StopException
        forker.send(:start_control_loop)
      end

      it 'resends the shutdown signal after a while' do
        allow(forker).to receive(:output)
        allow(forker).to receive(:shutdown_signal_pending?).and_return false
        allow(forker).to receive(:shutdown_signal_sent_before?).and_return true
        expect(forker).to receive(:resend_shutdown_signal).and_raise UnicornRelay::Forker::StopException
        forker.send(:start_control_loop)
      end

      it 'ends the control loop if the process group is empty' do
        allow(forker).to receive(:signal_process_group).and_raise Errno::ESRCH
        expect(forker).to receive(:check_if_process_group_empty).and_call_original
        expect(forker).to receive(:output).with('process group pgid=666 empty, exiting')
        forker.send(:start_control_loop)
      end
    end
  end

  describe '#stop_control_loop' do
    it 'raises UnicornRelay::Forker::StopException' do
      expect {
        forker.send(:stop_control_loop)
      }.to raise_error UnicornRelay::Forker::StopException
    end
  end
end
