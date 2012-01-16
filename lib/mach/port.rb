require 'mach/functions'

module Mach
  class Port
    include Functions

    attr_reader :ipc_space, :port

    # @param [Hash] opts
    #
    # @option opts [Integer] :ipc_space defaults to +mach_task_self+
    #
    # @option opts [MachPortRight] :right defaults to +:receive+
    #
    # @option opts [Port, Integer] :port if given, the existing port
    # is wrapped in a new Port object; otherwise a new port is
    # allocated according to the other options
    def initialize(opts = {})
      if opts.kind_of? Hash
        @ipc_space = opts[:ipc_space] || mach_task_self
        right = opts[:right] || :receive

        @port = if opts[:port]
                  opts[:port].kind_of?(Port) ? opts[:port].port : opts[:port]
                else
                  mem = new_memory_pointer(:mach_port_right_t)
                  mach_port_allocate(@ipc_space, right, mem)
                  mem.get_uint(0)
                end
      end
    end

    def ==(other)
      (port == other.port) && (ipc_space == other.ipc_space)
    end

    def destroy(opts = {})
      ipc_space = opts[:ipc_space] || @ipc_space
      mach_port_destroy(ipc_space, @port)
    end

    def deallocate(opts = {})
      ipc_space = opts[:ipc_space] || @ipc_space
      mach_port_deallocate(ipc_space, @port)
    end

    def insert_right(msg_type, opts = {})
      ipc_space = opts[:ipc_space] || @ipc_space
      port_name = opts[:port_name] || @port
      
      mach_port_insert_right(ipc_space, port_name, @port, msg_type)
    end
  end
end
