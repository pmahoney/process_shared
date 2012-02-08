require 'forwardable'

require 'process_shared'
require 'process_shared/open_with_self'
require 'process_shared/process_error'

module ProcessShared
  # BinarySemaphore is identical to Semaphore except that its value is
  # not permitted to rise above one (it may be either zero or one).
  # When the value is at the maximum, calls to #post will raise an
  # exception.
  #
  # This is identical to a Semaphore but with extra error checking.
  class BinarySemaphore
    extend Forwardable
    extend ProcessShared::OpenWithSelf

    def_delegators :@sem, :wait, :try_wait, :synchronize, :value, :close

    # Create a new semaphore with initial value +value+.  After
    # {Kernel#fork}, the semaphore will be shared across two (or more)
    # processes. The semaphore must be closed with {#close} in each
    # process that no longer needs the semaphore.
    #
    # (An object finalizer is registered that will close the semaphore
    # to avoid memory leaks, but this should be considered a last
    # resort).
    #
    # @param [Integer] value the initial semaphore value
    def initialize(value = 1)
      raise ArgumentErrror 'value must be 0 or 1' if (value < 0 or value > 1)
      @sem = Semaphore.new(value)
    end

    # Increment from zero to one.
    #
    # First, attempt to decrement.  If this fails with EAGAIN, the
    # semaphore was at zero, so continue with the post. If this
    # succeeds, the semaphore was not at zero, so increment back to
    # one and raise {ProcesError} (multiple workers may have acquired
    # the semaphore at this point).
    def post
      begin
        try_wait
        # oops, value was not zero...
        @sem.post
        raise ProcessError, 'post would raise value over bound'
      rescue Errno::EAGAIN
        # ok, value was zero
        @sem.post
      end
    end
  end
end
