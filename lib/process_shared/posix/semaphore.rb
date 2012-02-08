require 'process_shared/synchronizable_semaphore'
require 'process_shared/open_with_self'

require 'process_shared/posix/errno'
require 'process_shared/posix/libc'
require 'process_shared/posix/time_val'
require 'process_shared/posix/time_spec'

module ProcessShared
  module Posix
    class Semaphore
      module Foreign
        extend FFI::Library
        extend Errno
        
        ffi_lib 'rt' # 'pthread'

        typedef :pointer, :sem_p

        attach_function :sem_open, [:string, :int], :sem_p
        attach_function :sem_close, [:sem_p], :int
        attach_function :sem_unlink, [:string], :int

        attach_function :sem_init, [:sem_p, :int, :uint], :int
        attach_function :sem_destroy, [:sem_p], :int

        attach_function :sem_getvalue, [:sem_p, :pointer], :int
        attach_function :sem_post, [:sem_p], :int
        attach_function :sem_wait, [:sem_p], :int
        attach_function :sem_trywait, [:sem_p], :int
        attach_function :sem_timedwait, [:sem_p, TimeSpec], :int

        error_check(:sem_close, :sem_unlink, :sem_init, :sem_destroy,
                    :sem_getvalue, :sem_post, :sem_wait, :sem_trywait,
                    :sem_timedwait)
      end

      extend ProcessShared::OpenWithSelf
      include Foreign
      include ProcessShared::SynchronizableSemaphore

      # Make a Proc suitable for use as a finalizer that will call
      # +shm_unlink+ on +sem+.
      #
      # @return [Proc] a finalizer
      def self.make_finalizer(sem)
        proc { LibC.shm_unlink(sem) }
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
      def initialize(value = 1)
        @sem = SharedMemory.new(LibC.type_size(:sem_t))
        sem_init(@sem, 1, value)
        ObjectSpace.define_finalizer(self, self.class.make_finalizer(@sem))
      end

      # Get the current value of the semaphore. Raises {Errno::NOTSUP} on
      # platforms that don't support this (e.g. Mac OS X).
      #
      # @return [Integer] the current value of the semaphore.
      def value
        int = FFI::MemoryPointer.new(:int)
        sem_getvalue(@sem, int)
        int.read_int
      end

      # Increment the value of the semaphore.  If other processes are
      # waiting on this semaphore, one will be woken.
      def post
        sem_post(@sem)
      end

      # Decrement the value of the semaphore.  If the value is zero,
      # wait until another process increments via {#post}.
      def wait
        sem_wait(@sem)
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
          now = TimeVal.new
          LibC.gettimeofday(now, nil)
          abs_timeout = now.to_time_spec
          abs_timeout.add_seconds!(timeout)
          sem_timedwait(@sem, abs_timeout)
        else
          sem_trywait(@sem)
        end
      end

      # Close the shared memory block holding the semaphore.
      #
      # FIXME: May leak the semaphore memory on some platforms,
      # according to the Linux man page for sem_destroy(3). (Should not
      # be destroyed as it may be in use by other processes.)
      def close
        # sem_destroy(@sem)

        # Not entirely sure what to do here.  sem_destroy() goes with
        # sem_init() (unnamed semaphroe), but other processes cannot use
        # a destroyed semaphore.
        @sem.close
        @sem = nil
        ObjectSpace.undefine_finalizer(self)
      end
    end
  end
end
