require 'spec_helper'
require 'process_shared'

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

    describe 'Object dump/load' do
      it 'writes serialized objects' do
        mem = SharedMemory.new(1024)
        pid = fork do
          mem.write_object(['a', 'b'])
          Kernel.exit!
        end
        ::Process.wait(pid)
        mem.read_object.must_equal ['a', 'b']
      end
      
      it 'raises IndexError when insufficient space' do
        mem = SharedMemory.new(2)
        proc { mem.write_object(['a', 'b']) }.must_raise(IndexError)
      end

      it 'writes with an offset' do
        mem = SharedMemory.new(1024)
        mem.put_object(2, 'string')
        proc { mem.read_object }.must_raise(TypeError)
        proc { mem.get_object(0) }.must_raise(TypeError)
        mem.get_object(2).must_equal 'string'
      end
    end
  end
end
