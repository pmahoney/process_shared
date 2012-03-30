require 'spec_helper'
require 'process_shared'

module ProcessShared
  describe Monitor do

    include LockBehavior

    before :each do
      @lock = Monitor.new
    end

    it 'raises exception when unlocked by other process' do
      pid = Kernel.fork do
        @lock.lock
        sleep 0.2
        @lock.unlock
        Kernel.exit!
      end

      sleep 0.1
      proc { @lock.unlock }.must_raise(ProcessError)

      ::Process.wait(pid)
    end

    it 'raises nothing with nested lock' do
      @lock.lock
      @lock.lock
      @lock.unlock
      @lock.unlock
    end
  end
end
