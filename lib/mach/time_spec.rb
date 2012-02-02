require 'ffi'

module Mach
  class TimeSpec < FFI::Struct
    layout(:tv_sec, :uint,
           :tv_nsec, :int)      # clock_res_t

    def to_s
      "#<%s tv_sec=%d tv_nsec=%d>" % [self.class,
                                      self[:tv_sec],
                                      self[:tv_nsec]]
      
    end
  end
end

