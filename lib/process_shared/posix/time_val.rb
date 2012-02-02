require 'ffi'

require 'process_shared/posix/time_spec'

module ProcessShared
  module Posix
    class TimeVal < FFI::Struct
      US_PER_NS = 1000

      layout(:tv_sec, :time_t,
             :tv_usec, :suseconds_t)

      def to_time_spec
        ts = TimeSpec.new

        ts[:tv_sec] = self[:tv_sec];
        ts[:tv_nsec] = self[:tv_usec] * US_PER_NS

        ts
      end
    end
  end
end
