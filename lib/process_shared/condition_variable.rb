require 'process_shared/semaphore'

module ProcessShared
  # TODO: implement this
  class ConditionVariable
    def initialize
      @sem = Semaphore.new
    end

    def broadcast
      @sem.post
    end

    def signal
      @sem.post
    end

    def wait(mutex, timeout = nil)
      mutex.unlock
      begin
        @sem.wait
      ensure
        mutex.lock
      end
    end
  end
end
