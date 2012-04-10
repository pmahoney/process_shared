require 'process_shared'
require 'process_shared/open_with_self'
require 'process_shared/process_error'

module ProcessShared
  # This Mutex class is implemented as a Semaphore with a second
  # internal Semaphore used to track the locking process is tracked.
  # {ProcessError} is raised if either {#unlock} is called by a
  # process different from the locking process, or if {#lock} is
  # called while the process already holds the lock (i.e. the mutex is
  # not re-entrant).  This tracking is not without performance cost,
  # of course (current implementation uses the additional {Semaphore}
  # and {SharedMemory} segment).
  #
  # The API is intended to be identical to the {::Mutex} in the core
  # Ruby library.
  #
  # TODO: the core Ruby api has no #close method, but this Mutex must
  # release its {Semaphore} and {SharedMemory} resources.  For now,
  # rely on the object finalizers of those objects...
  class Mutex
    extend OpenWithSelf

    def initialize
      @internal_sem = Semaphore.new
      @locked_by = SharedMemory.new(:int)

      @sem = Semaphore.new
      @_cv ||= ConditionVariable.new
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
    # non-nil or unless #wakeup_first is called, i.e.
    # fork { mutex.synchronize { mutex.sleep } }
    # sleep 0.2; mutex.wakeup_first # wakes up the first process, like Thread#wakeup would in threaded land
    #
    # @return [Numeric]
    def sleep(timeout = nil)
      assert_held_by_this_process
      @_cv.wait(self, timeout)
    end

    # wakes up first process 'sleeping' on this mutex, like Thread#wakeup
    # not sure what it returns.
    def wakeup_first
      @_cv.signal
    end

    # @return [Boolean]
    def try_lock
      with_internal_lock do
        if @locked_by.get_int(0) > 0
          false                 # was locked
        else
          @sem.wait             # should return immediately
          self.locked_by = ::Process.pid
          true
        end
      end
    end

    private
    def assert_held_by_this_process
      if (p = locked_by) != ::Process.pid
        raise ProcessError, "lock is held by #{p} not #{::Process.pid}"
      end
    end
    public

    # @return [Mutex]
    def unlock
      assert_held_by_this_process
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

    protected

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

    def with_internal_lock(&block)
      @internal_sem.synchronize &block
    end
  end
end
