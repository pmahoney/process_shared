require 'process_shared'
require 'process_shared/open_with_self'
require 'process_shared/process_error'

module ProcessShared
  # This Mutex class is implemented as a Semaphore with a second
  # internal Semaphore used to track the locking process and thread.
  #
  # {ProcessError} is raised if either {#unlock} is called by a
  # process + thread different from the locking process + thread, or
  # if {#lock} is called while the process + thread already holds the
  # lock (i.e. the mutex is not re-entrant).  This tracking is not
  # without performance cost, of course (current implementation uses
  # the additional {Semaphore} and {SharedMemory} segment).
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
      @locked_by = SharedMemory.new(:uint64, 2)  # [Process ID, Thread ID]

      @sem = Semaphore.new
    end

    # @return [Mutex]
    def lock
      if (p, t = current_process_and_thread) == locked_by
        raise ProcessError, "already locked by this process #{p}, thread #{t}"
      end

      @sem.wait
      self.locked_by = current_process_and_thread
      self
    end

    # @return [Boolean]
    def locked?
      locked_by != UNLOCKED
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
        if locked?
          false                 # was locked
        else
          @sem.wait             # should return immediately
          self.locked_by = current_process_and_thread
          true
        end
      end
    end

    # @return [Mutex]
    def unlock
      if (p, t = locked_by) != (cp, ct = current_process_and_thread)
        raise ProcessError, "lock is held by process #{p}, thread #{t}: not process #{cp}, thread #{ct}"
      end

      self.locked_by = UNLOCKED
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

    # @return [Array<(Fixnum, Fixnum)>]
    #   If locked, IDs of the locking process and thread, otherwise +UNLOCKED+
    def locked_by
      with_internal_lock do
        @locked_by.read_array_of_uint64(2)
      end
    end

    # @param [Array<(Fixnum, Fixnum)>] ary
    #   Set the IDs of the locking process and thread, or +UNLOCKED+ if none
    def locked_by=(ary)
      with_internal_lock do
        @locked_by.write_array_of_uint64(ary)
      end
    end

    def with_internal_lock(&block)
      @internal_sem.synchronize &block
    end

    # @return [Array<(Fixnum, Fixnum)>]  IDs of the current process and thread
    def current_process_and_thread
      [::Process.pid, Thread.current.object_id]
    end

    # Represents the state of being unlocked
    UNLOCKED = [0, 0].freeze
  end
end
