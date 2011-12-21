require 'process_shared/rt'
require 'process_shared/libc'
require 'process_shared/with_self'
require 'process_shared/shared_memory_io'

module ProcessShared
  # Memory block shared across processes.
  class SharedMemory < FFI::Pointer
    include WithSelf

    attr_reader :size, :type, :type_size, :count, :fd

    def self.open(size, &block)
      new(size).with_self(&block)
    end

    def self.make_finalizer(addr, size, fd)
      proc do
        pointer = FFI::Pointer.new(addr)
        LibC.munmap(pointer, size)
        LibC.close(fd)
      end
    end

    def initialize(type_or_count = 1, count = 1)
      @type, @count = case type_or_count
                      when Symbol
                        [type_or_count, count]
                      else
                        [:uchar, type_or_count]
                      end

      @type_size = FFI.type_size(@type)
      @size = @type_size * @count

      name = "/ps-shm#{rand(10000)}"
      @fd = RT.shm_open(name,
                        LibC::O_CREAT | LibC::O_RDWR | LibC::O_EXCL,
                        0777)
      RT.shm_unlink(name)
      
      LibC.ftruncate(@fd, @size)
      @pointer = LibC.mmap(nil,
                           @size,
                           LibC::PROT_READ | LibC::PROT_WRITE,
                           LibC::MAP_SHARED,
                           @fd,
                           0).
        slice(0, size) # slice to get FFI::Pointer that knows its size
                       # (and thus does bounds checking)

      @finalize = self.class.make_finalizer(@pointer.address, @size, @fd)
      ObjectSpace.define_finalizer(self, @finalize)

      super(@pointer)
    end

    # Write the serialization of +obj+ (using Marshal.dump) to this
    # shared memory object at +offset+ (in bytes).
    #
    # Raises IndexError if there is insufficient space.
    def put_object(offset, obj)
      io = SharedMemoryIO.new(self)
      io.seek(offset)
      Marshal.dump(obj, io)
    end

    # Read the serialized object at +offset+ (in bytes) using
    # Marshal.load.
    #
    # @return [Object]
    def get_object(offset)
      io = to_shm_io
      io.seek(offset)
      Marshal.load(io)
    end

    # Equivalent to {#put_object(0, obj)}
    def write_object(obj)
      Marshal.dump(obj, to_shm_io)
    end

    # Equivalent to {#read_object(0, obj)}
    #
    # @return [Object]
    def read_object
      Marshal.load(to_shm_io)
    end

    def close
      ObjectSpace.undefine_finalizer(self)
      @finalize.call
    end

    private

    def to_shm_io
      SharedMemoryIO.new(self)
    end
  end
end
