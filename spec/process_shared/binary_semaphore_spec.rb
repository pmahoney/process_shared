require 'spec_helper'
require 'process_shared/binary_semaphore'

module ProcessShared
  describe BinarySemaphore do
    it 'raises exception with double post' do
      BinarySemaphore.open(0) do |sem|
        sem.post
        proc { sem.post }.must_raise(ProcessError)
      end
    end
  end
end
