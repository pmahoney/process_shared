require 'process_shared/with_self'

module ProcessShared
  module Semaphore
    include ProcessShared::WithSelf

    class << self
      # the implementation to use to create semaphores.  impl is set
      # based on the platform in 'process_shared'
      attr_accessor :impl
      
      def new(*args)
        impl.new(*args)
      end

      # With no associated block, open is a synonym for
      # Semaphore.new. If the optional code block is given, it will be
      # passed +sem+ as an argument, and the Semaphore object will
      # automatically be closed when the block terminates. In this
      # instance, Semaphore.open returns the value of the block.
      #
      # @param [Integer] value the initial semaphore value
      def open(value = 1, &block)
        new(value).with_self(&block)
      end
    end

    def synchronize
      wait
      begin
        yield
      ensure
        post
      end
    end
  end
end
