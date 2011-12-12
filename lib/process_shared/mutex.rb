require 'process_shared/bounded_semaphore'
require 'process_shared/with_self'
require 'process_shared/shared_memory'
require 'process_shared/process_error'

module ProcessShared
  class Mutex
    include WithSelf

    def self.open(&block)
      new.with_self(&block)
    end

    def initialize
      @internal_sem = BoundedSemaphore.new(1)
      @locked_by = SharedMemory.new(:int)

      @sem = BoundedSemaphore.new(1)
    end

    # @return [Mutex]
    def lock
      @sem.wait
      self.locked_by = ::Process.pid
      self
    end

    # @return [Boolean]
    def locked?
      locked_by > 0
    end

    # Releases the lock and sleeps timeout seconds if it is given and
    # non-nil or forever.
    #
    # @return [Numeric]
    def sleep(timeout = nil)
      unlock
      begin
        timeout ? sleep(timeout) : sleep
      ensure
        lock
      end
    end

    # @return [Boolean]
    def try_lock
      with_internal_lock do
        if @locked_by.get_int(0) > 0
          false                 # was locked
        else
          @sem.wait
          self.locked_by = ::Process.pid
          true
        end
      end
    end

    # @return [Mutex]
    def unlock
      if (p = locked_by) != ::Process.pid
        raise ProcessError, "lock is held by #{p} not #{::Process.pid}"
      end

      @sem.post
      self
    end

    # Acquire the lock, yield the block, then ensure the lock is
    # unlocked.
    def synchronize
      lock
      begin
        yield
      ensure
        unlock
      end
    end

    private

    def locked_by
      with_internal_lock do
        @locked_by.get_int(0)
      end
    end

    def locked_by=(val)
      with_internal_lock do
        @locked_by.put_int(0, val)
      end
    end

    def with_internal_lock
      @internal_sem.wait
      begin
        yield
      ensure
        @internal_sem.post
      end
    end
  end
end
