require 'process_shared'

module ProcessShared
  class ConditionVariable
    def initialize
      @internal = Semaphore.new(1)
      @waiting = SharedMemory.new(:int)
      @waiting.write_int(0)
      @sem = Semaphore.new(0)
    end

    def broadcast
      @internal.synchronize do
        @waiting.read_int.times { @sem.post }
      end
    end

    def signal
      @sem.post
    end

    def wait(mutex, timeout = nil)
      mutex.unlock
      begin
        inc_waiting
        if timeout
          begin
            @sem.try_wait(timeout)
          rescue Errno::EAGAIN, Errno::ETIMEDOUT
            # success!
          end
        else
          @sem.wait
        end
        dec_waiting
      ensure
        mutex.lock
      end
    end

    private

    def inc_waiting(val = 1)
      @internal.synchronize do
        @waiting.write_int(@waiting.read_int + val)
      end
    end

    def dec_waiting
      inc_waiting(-1)
    end
  end
end
