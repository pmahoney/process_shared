require 'spec_helper'
require 'process_shared/shared_memory'

module ProcessShared
  describe SharedMemory do
    it 'shares memory across processes' do
      mem = SharedMemory.new(1)
      mem.put_char(0, 0)
      mem.get_char(0).must_equal(0)
      
      pid = fork do
        mem.put_char(0, 123)
        Kernel.exit!
      end

      ::Process.wait(pid)

      mem.get_char(0).must_equal(123)
    end

    it 'initializes with type symbol' do
      mem = SharedMemory.new(:int)
      mem.put_int(0, 0)
      mem.get_int(0).must_equal(0)
      
      pid = fork do
        mem.put_int(0, 1234567)
        Kernel.exit!
      end

      ::Process.wait(pid)

      mem.get_int(0).must_equal(1234567)
    end
  end
end
