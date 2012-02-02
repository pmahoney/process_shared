require 'mach/functions'
require 'mach/port'
require 'mach/clock'

module Mach
  class Host < Port
    include Functions

    # @return [Task]
    def self.self
      new(Functions.mach_host_self)
    end

    def initialize(host)
      super(:port => host)
    end

    alias_method :host, :port

    def get_clock_service
      mem = new_memory_pointer(:clock_id_t)
      host_get_clock_service(host, 0, mem)
      clock_id = Port.new(:port => mem.read_int)
      Clock.new clock_id
    end
  end
end

