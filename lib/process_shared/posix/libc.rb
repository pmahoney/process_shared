require 'ffi'

require 'process_shared/posix/errno'
require 'process_shared/posix/time_val'

module ProcessShared
  module Posix
    module LibC
      module Helper
        extend FFI::Library

        # Workaround FFI dylib/bundle issue.  See https://github.com/ffi/ffi/issues/42
        suffix = if FFI::Platform.mac?
                   'bundle'
                 else
                   FFI::Platform::LIBSUFFIX
                 end

        ffi_lib File.join(File.expand_path(File.dirname(__FILE__)),
                          'helper.' + suffix)
        
        [:o_rdwr,
         :o_creat,
         :o_excl,
         
         :prot_read,
         :prot_write,
         :prot_exec,
         :prot_none,
         
         :map_shared,
         :map_private].each do |sym|
          attach_variable sym, :int
        end

        [:sizeof_sem_t].each do |sym|
          attach_variable sym, :size_t
        end
      end

      extend FFI::Library
      extend Errno

      ffi_lib FFI::Library::LIBC

      MAP_FAILED = FFI::Pointer.new(-1)
      MAP_SHARED = Helper.map_shared
      MAP_PRIVATE = Helper.map_private

      PROT_READ = Helper.prot_read
      PROT_WRITE = Helper.prot_write
      PROT_EXEC = Helper.prot_exec
      PROT_NONE = Helper.prot_none

      O_RDWR = Helper.o_rdwr
      O_CREAT = Helper.o_creat
      O_EXCL = Helper.o_excl

      def self.type_size(type)
        case type
        when :sem_t
          Helper.sizeof_sem_t
        else
          FFI.type_size(type)
        end
      end

      attach_function :mmap, [:pointer, :size_t, :int, :int, :int, :off_t], :pointer
      attach_function :munmap, [:pointer, :size_t], :int
      attach_function :ftruncate, [:int, :off_t], :int
      attach_function :close, [:int], :int
      attach_function :gettimeofday, [TimeVal, :pointer], :int

      error_check(:mmap) { |v| v == MAP_FAILED }
      error_check(:munmap, :ftruncate, :close, :gettimeofday)
    end
  end
end
