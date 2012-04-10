require 'spec_helper'

require 'process_shared/condition_variable'

module ProcessShared

  describe ConditionVariable do
    it 'has a Mutex#sleep/wakeup method' do
      mutex = Mutex.new
      mem = SharedMemory.new(:int)
      mem.write_int(0)

      a = fork {
        mutex.synchronize {
          mutex.sleep
        }
        mem.write_int(1)
        Kernel.exit!
      }
      sleep 0.2 
      b = fork {
        mutex.wakeup_first
        Kernel.exit!
      }

      ::Process.wait(a)
      ::Process.wait(b)
      mem.read_int.must_equal(1)
    end

  end

end
