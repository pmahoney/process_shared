require 'process_shared/bounded_semaphore'
require 'process_shared/with_self'
require 'process_shared/shared_memory'
require 'process_shared/process_error'

module ProcessShared
  # This Mutex class is implemented as a BoundedSemaphore with a
  # maximum value of 1.  Additionally, the locking process is tracked,
  # and {ProcessError} is raised if either {#unlock} is called by a
  # process different from the locking process, or if {#lock} is
  # called while the process already holds the lock (i.e. the mutex is
  # not re-entrant).  This tracking is not without performance cost,
  # of course (current implementation uses an additional
  # {BoundedSemaphore} and {SharedMemory} segment).
  #
  # The API is intended to be identical to the {::Mutex} in the core
  # Ruby library.
  #
  # TODO: the core Ruby api has no #close method, but this Mutex must
  # release its {BoundedSemaphore} and {SharedMemory} resources.  For
  # now, rely on the object finalizers of those objects...
  class Mutex
    # include WithSelf

    # def self.open(&block)
    #   new.with_self(&block)
    # end

    def initialize
      @internal_sem = BoundedSemaphore.new(1)
      @locked_by = SharedMemory.new(:int)

      @sem = BoundedSemaphore.new(1)
    end

    # @return [Mutex]
    def lock
      if locked_by == ::Process.pid
        raise ProcessError, "already locked by this process #{::Process.pid}"
      end

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
        timeout ? Kernel.sleep(timeout) : Kernel.sleep
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

      self.locked_by = 0
      @sem.post
      self
    end

    # Acquire the lock, yield the block, then ensure the lock is
    # unlocked.
    #
    # @return [Object] the result of the block
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
