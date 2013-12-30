require 'forwardable'

module ProcessShared
  module SynchronizableSemaphore
    # Yield the block after decrementing the semaphore, ensuring that
    # the semaphore is incremented.
    #
    # @return [Object] the value of the block
    def synchronize
      wait
      begin
        yield
      ensure
        post
      end
    end

    # Expose an unchecked mutex-like interface using only this semaphore.
    #
    # @return [FasterUncheckedMutex]  An unchecked mutex facade for this semaphore
    def to_mtx
      FasterUncheckedMutex.new(self)
    end

    private

    # @api private
    #
    # Presents a mutex-like facade over a semaphore.
    # @see SynchronizableSemaphore#to_mtx
    #
    # NOTE: Unlocking a locked mutex from a different process or thread than
    # that which locked it will result in undefined behavior, whereas with the
    # Mutex class, this error will be detected and an exception raised.
    #
    # It is recommended to develop using the Mutex class, which is checked, and
    # to use this unchecked variant only to optimized performance for code paths
    # that have been determined to have correct lock/unlock behavior.
    class FasterUncheckedMutex
      extend Forwardable

      def initialize(sem)
        @sem = sem
      end

      # @return [Boolean]  +true+ if currently locked
      def locked?
        @sem.try_wait
        @sem.post
        false
      rescue Errno::EAGAIN
        true
      end

      # Releases the lock and sleeps timeout seconds if it is given and
      # non-nil or forever.
      #
      # TODO: de-duplicate this from Mutex#sleep
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

      # @return [Boolean]  +true+ if lock was acquired, +false+ if already locked
      def try_lock
        @sem.try_wait
        true
      rescue Errno::EAGAIN
        false
      end

      # delegate to methods with different names
      def_delegator :@sem, :wait, :lock
      def_delegator :@sem, :post, :unlock

      # delegate to methods with the same names
      def_delegators :@sem, :synchronize, :close
    end

  end
end
