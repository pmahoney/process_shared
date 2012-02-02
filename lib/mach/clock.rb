require 'mach/functions'
require 'mach/port'
require 'mach/time_spec'

module Mach
  class Clock
    include Functions

    def initialize(clock_id)
      @clock_id = clock_id
    end

    def to_s
      "#<#{self.class} #{@clock_id.to_i}>"
    end

    def get_time
      time = TimeSpec.new
      clock_get_time(@clock_id.to_i, time)
      time
    end
  end
end

