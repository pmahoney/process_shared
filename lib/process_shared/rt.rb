require 'process_shared/posix_call'
require 'process_shared/psem'

module ProcessShared
  module RT
    extend FFI::Library
    extend PosixCall

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
end
