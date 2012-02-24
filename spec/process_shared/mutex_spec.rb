require 'spec_helper'
require 'process_shared'

module ProcessShared
  describe Mutex do

    include LockBehavior

    before :each do
      @lock = Mutex.new
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

    it 'raises exception when locked twice by same process' do
      @lock.lock
      proc { @lock.lock }.must_raise(ProcessError)
      @lock.unlock
    end
  end
end
