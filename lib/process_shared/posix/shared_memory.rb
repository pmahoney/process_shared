require 'ffi'

require 'process_shared/posix/errno'
require 'process_shared/posix/libc'
require 'process_shared/object_buffer'
require 'process_shared/open_with_self'

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

      extend ProcessShared::OpenWithSelf
      include SharedMemory::Foreign
      include LibC
      include ProcessShared::ObjectBuffer

      attr_reader :size, :type, :type_size, :count, :fd

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

      def close
        ObjectSpace.undefine_finalizer(self)
        @finalize.call
      end
    end
  end
end
