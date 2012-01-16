require 'mach/functions'
require 'mach/port'

module Mach
  class Task < Port
    include Functions

    # @return [Task]
    def self.self
      new(Functions.mach_task_self)
    end

    def initialize(task)
      super(:port => task)
    end

    alias_method :task, :port

    # @param [MachSpecialPort] which_port
    def get_special_port(which_port)
      mem = FFI::MemoryPointer.new(:int)
      task_get_special_port(task, which_port, mem)
      Port.new(:port => mem.get_int(0))
    end

    # @param [MachSpecialPort] which_port
    #
    # @param [Port,Integer] newport
    def set_special_port(which_port, newport)
      p = newport.respond_to?(:port) ? newport.port : newport
      task_set_special_port(task, which_port, p)
    end

    def get_bootstrap_port
      get_special_port(:bootstrap)
    end

    def set_bootstrap_port(port)
      set_special_port(:bootstrap, port)
    end
  end
end

