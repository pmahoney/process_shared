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
  end
end
