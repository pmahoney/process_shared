require 'ffi'
require 'process_shared/time_spec'

module ProcessShared
  module Posix
    class TimeSpec < FFI::Struct
      include ProcessShared::TimeSpec

      layout(:tv_sec, :time_t,
             :tv_nsec, :long)
    end
  end
end
