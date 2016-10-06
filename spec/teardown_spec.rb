require 'spec_helper'

describe UnicornRelay::Teardown do
  let :server do
    double('Server')
  end

  let :teardown do
    described_class.new(server: server, pid_file: 'foo/bar.pid.oldbin')
  end

  it 'does not perform without new pid_file' do
    allow(teardown).to receive(:server_has_new_pid_file?).and_return false
    allow(teardown).to receive(:pid).and_return 666
    teardown.perform
    expect(teardown).not_to receive(:kill_pid)
  end

  it 'does not perform without a pid in pid_file' do
    allow(teardown).to receive(:server_has_new_pid_file?).and_return true
    teardown.perform
    expect(teardown).not_to receive(:kill_pid)
  end

  it 'performs killing otherwise' do
    allow(teardown).to receive(:server_has_new_pid_file?).and_return true
    allow(teardown).to receive(:pid).and_return 666
    expect(Process).to receive(:kill).with(:QUIT, 666)
    expect(teardown).to receive(:kill_pid).and_call_original
    teardown.perform
  end

  describe '#kill_pid' do
    it 'returns nil if process for pid is not found' do
      allow(Process).to receive(:kill).and_raise Errno::ESRCH
      expect(teardown.send(:kill_pid)).to be_nil
    end

  end

  describe '#pid' do
    it 'returns nil for missing pid file or non-numeric content' do
      allow(teardown).to receive(:pid_file_content).and_return 'nix'
      expect(teardown.send(:pid)).to be_nil
    end
  end

  describe '#server_has_new_pid_file?' do
    it 'returns true if server.pid is different from pid_file' do
      allow(server).to receive(:pid).and_return 'something else'
      allow(teardown).to receive(:pid_file_exist?).and_return true
      expect(teardown.send(:server_has_new_pid_file?)).to eq true
    end

    it 'returns false if server.pid is the same as pid_file' do
      allow(server).to receive(:pid).and_return 'foo/bar.pid.oldbin'
      allow(teardown).to receive(:pid_file_exist?).and_return true
      expect(teardown.send(:server_has_new_pid_file?)).to eq false
    end

    it 'returns false if pid_file does not exist' do
      allow(teardown).to receive(:pid_file_exist?).and_return false
      expect(teardown.send(:server_has_new_pid_file?)).to eq false
    end
  end

  describe '#pid_file_exist?' do
    it 'checks the existence of pid_file' do
      expect(File).to receive(:exist?).with('foo/bar.pid.oldbin')
      teardown.send(:pid_file_exist?)
    end
  end
end
