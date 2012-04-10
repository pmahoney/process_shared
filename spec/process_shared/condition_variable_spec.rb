require 'spec_helper'

require 'process_shared/condition_variable'

module ProcessShared
  describe ConditionVariable do
    it 'runs the example of Ruby Stdlib ConditionVariable' do
      mutex = Mutex.new
      resource = ConditionVariable.new

      a = fork {
        mutex.synchronize {
          resource.wait(mutex)
        }
        Kernel.exit!
      }
      
      b = fork {
        mutex.synchronize {
          resource.signal
        }
        Kernel.exit!
      }

      ::Process.wait(a)
      ::Process.wait(b)
    end

    it 'can signal outside the mutex' do
      mutex = Mutex.new
      resource = ConditionVariable.new
      mem = SharedMemory.new(:int)
      mem.write_int(0)

      a = fork {
        mutex.synchronize {
          resource.wait(mutex)
        }
        mem.write_int 1
        Kernel.exit!
      }
      sleep 0.2
      b = fork {
        resource.signal
        Kernel.exit!
      }

      ::Process.wait(a)
      ::Process.wait(b)
      mem.read_int.must_equal(1)
    end

    it 'broadcasts to multiple processes' do
      mutex = Mutex.new
      cond = ConditionVariable.new
      mem = SharedMemory.new(:int)
      mem.write_int(0)

      pids = []
      10.times do
        pids << fork do
          mutex.synchronize {
            cond.wait(mutex)
            mem.write_int(mem.read_int + 1)
          }
          Kernel.exit!
        end
      end

      sleep 0.2               # hopefully they are all waiting...
      mutex.synchronize {
        cond.broadcast
      }

      pids.each { |p| ::Process.wait(p) }

      mem.read_int.must_equal(10)
    end

    it 'stops waiting after timeout' do
      mutex = Mutex.new
      cond = ConditionVariable.new

      mutex.synchronize {
        start = Time.now.to_f
        cond.wait(mutex, 0.1)
        (Time.now.to_f - start).must be_gte(0.1)
      }
    end
  end
end
