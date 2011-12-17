require 'process_shared/semaphore'

module ProcessShared
  class ConditionVariable
    def initialize
      @internal = Semaphore.new(1)
      @waiting = SharedMemory.new(:int)
      @waiting.write_int(0)
      @sem = Semaphore.new(0)
    end

    def broadcast
      waiting.times { @sem.post }
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

    def waiting
      @internal.synchronize do
        @waiting.read_int
      end
    end

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
