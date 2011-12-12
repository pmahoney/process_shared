require 'ffi'

require 'process_shared/posix_call'
require 'process_shared/psem'

module ProcessShared
  module LibC
    extend FFI::Library
    extend PosixCall

    ffi_lib FFI::Library::LIBC

    MAP_FAILED = FFI::Pointer.new(-1)
    MAP_SHARED = PSem.map_shared
    MAP_PRIVATE = PSem.map_private

    PROT_READ = PSem.prot_read
    PROT_WRITE = PSem.prot_write
    PROT_EXEC = PSem.prot_exec
    PROT_NONE = PSem.prot_none

    O_RDWR = PSem.o_rdwr
    O_CREAT = PSem.o_creat
    O_EXCL = PSem.o_excl

    attach_variable :errno, :int

    attach_function :mmap, [:pointer, :size_t, :int, :int, :int, :off_t], :pointer
    attach_function :munmap, [:pointer, :size_t], :int
    attach_function :ftruncate, [:int, :off_t], :int
    attach_function :close, [:int], :int

    error_check(:mmap) { |v| v == MAP_FAILED }
    error_check(:munmap, :ftruncate, :close)
  end
end
