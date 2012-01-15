require 'mach/functions'

module Mach
  class Port
    include Functions

    attr_reader :ipc_space, :port

    # either initialize(port, opts) -or- initialize(opts)
    def initialize(opts = {}, opts2 = {})
      if opts.kind_of? Hash
        ipc_space = opts[:ipc_space] || mach_task_self
        right = opts[:right] || :receive

        mem = new_memory_pointer(:mach_port_right_t)
        mach_port_allocate(ipc_space, right, mem)

        @port = mem.get_uint(0)
        @ipc_space = ipc_space
      else
        @port = opts
        @ipc_space = opts2[:ipc_space] || mach_task_self
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
