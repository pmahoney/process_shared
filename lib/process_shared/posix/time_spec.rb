require 'ffi'

module ProcessShared
  module Posix
    class TimeSpec < FFI::Struct
      layout(:tv_sec, :time_t,
             :tv_nsec, :long)
    end
  end
end
