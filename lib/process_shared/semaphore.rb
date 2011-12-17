require 'process_shared/psem'
require 'process_shared/abstract_semaphore'

module ProcessShared
  class Semaphore < AbstractSemaphore
    # With no associated block, open is a synonym for
    # Semaphore.new. If the optional code block is given, it will be
    # passed +sem+ as an argument, and the Semaphore object will
    # automatically be closed when the block terminates. In this
    # instance, Semaphore.open returns the value of the block.
    #
    # @param [Integer] value the initial semaphore value
    # @param [String] name not currently supported
    def self.open(value = 1, name = nil, &block)
      new(value, name).with_self(&block)
    end

    # Create a new semaphore with initial value +value+.  After
    # Kernel#fork, the semaphore will be shared across two (or more)
    # processes. The semaphore must be closed with #close in each
    # process that no longer needs the semaphore.
    #
    # (An object finalizer is registered that will close the semaphore
    # to avoid memory leaks, but this should be considered a last
    # resort).
    #
    # @param [Integer] value the initial semaphore value
    # @param [String] name not currently supported
    def initialize(value = 1, name = nil)
      init(PSem.sizeof_psem_t, 'psem', name) do |sem_name|
        psem_open(sem, sem_name, value, err)
      end
    end

    # Decrement the value of the semaphore.  If the value is zero,
    # wait until another process increments via {#post}.
    def wait
      psem_wait(sem, err)
    end

    # Decrement the value of the semaphore if it can be done
    # immediately (i.e. if it was non-zero).  Otherwise, wait up to
    # +timeout+ seconds until another process increments via {#post}.
    #
    # @param timeout [Numeric] the maximum seconds to wait, or nil to not wait
    #
    # @return If +timeout+ is nil and the semaphore cannot be
    # decremented immediately, raise Errno::EAGAIN.  If +timeout+
    # passed before the semaphore could be decremented, raise
    # Errno::ETIMEDOUT.
    def try_wait(timeout = nil)
      if timeout
        psem_timedwait(sem, timeout, err)
      else
        psem_trywait(sem, err)
      end
    end

    # Increment the value of the semaphore.  If other processes are
    # waiting on this semaphore, one will be woken.
    def post
      psem_post(sem, err)
    end

    # Get the current value of the semaphore. Raises {Errno::NOTSUP} on
    # platforms that don't support this (e.g. Mac OS X).
    #
    # @return [Integer] the current value of the semaphore.
    def value
      int = FFI::MemoryPointer.new(:int)
      psem_getvalue(sem, int, err)
      int.get_int(0)
    end

    # Release the resources associated with this semaphore.  Calls to
    # other methods are undefined after {#close} has been called.
    #
    # Close must be called when the semaphore is no longer needed.  An
    # object finalizer will close the semaphore as a last resort.
    def close
      psem_close(sem, err)
    end
  end
end
