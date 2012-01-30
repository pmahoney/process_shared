require 'ffi'

require 'process_shared/posix/errno'
require 'process_shared/posix/libc'
require 'process_shared/shared_memory_io'
require 'process_shared/with_self'

module ProcessShared
  module Posix
    # Memory block shared across processes.
    class SharedMemory < FFI::Pointer
      module Foreign
        extend FFI::Library
        extend Errno

        # FIXME: mac and linux OK, but what about everything else?
        if FFI::Platform.mac?
          ffi_lib 'c'
        else
          ffi_lib 'rt'
        end

        attach_function :shm_open, [:string, :int, :mode_t], :int
        attach_function :shm_unlink, [:string], :int
        
        error_check :shm_open, :shm_unlink
      end

      include SharedMemory::Foreign
      include LibC
      
      include ProcessShared::WithSelf

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
        @fd = shm_open(name,
                       O_CREAT | O_RDWR | O_EXCL,
                       0777)
        shm_unlink(name)
        
        ftruncate(@fd, @size)
        @pointer = mmap(nil,
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
        # FIXME: This is a workaround to an issue I'm seeing in
        # 1.8.7-p352 (not tested in other 1.8's).  If I used the code
        # below that works in 1.9, then inside SharedMemoryIO#write, the
        # passed string object is 'terminated' (garbage collected?) and
        # won't respond to any methods...  This less efficient since it
        # involves the creation of an intermediate string, but it works
        # in 1.8.7-p352.
        if RUBY_VERSION =~ /^1.8/
          str = Marshal.dump(obj)
          return put_bytes(offset, str, 0, str.size)
        end

        io = to_shm_io
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
        put_object(0, obj)
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
        ProcessShared::SharedMemoryIO.new(self)
      end
    end
  end
end
