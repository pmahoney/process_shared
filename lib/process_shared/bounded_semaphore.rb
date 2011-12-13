require 'process_shared/psem'
require 'process_shared/semaphore'

module ProcessShared
  # BoundedSemaphore is identical to Semaphore except that its value
  # is not permitted to rise above a maximum.  When the value is at
  # the maximum, calls to #post will have no effect.
  class BoundedSemaphore < Semaphore
    # With no associated block, open is a synonym for
    # Semaphore.new. If the optional code block is given, it will be
    # passed +sem+ as an argument, and the Semaphore object will
    # automatically be closed when the block terminates. In this
    # instance, BoundedSemaphore.open returns the value of the block.
    #
    # @param [Integer] value the initial semaphore value
    # @param [String] name not currently supported
    def self.open(maxvalue, value = 1, name = nil, &block)
      new(maxvalue, value, name).with_self(&block)
    end

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
    # @param [String] name not currently supported
    def initialize(maxvalue, value = 1, name = nil)
      init(PSem.sizeof_bsem_t, 'bsem', name) do |sem_name|
        bsem_open(sem, sem_name, maxvalue, value, err)
      end
    end

    protected

    alias_method :psem_unlink, :bsem_unlink
    alias_method :psem_close, :bsem_close
    alias_method :psem_wait, :bsem_wait
    alias_method :psem_post, :bsem_post
    alias_method :psem_getvalue, :bsem_getvalue
  end
end
