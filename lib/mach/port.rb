require 'ffi'
require 'mach/functions'

module Mach
  # Michael Weber's "Some Fun with Mach Ports" was an indispensable
  # resource in learning the Mach ports API.
  #
  # @see http://www.foldr.org/~michaelw/log/computers/macosx/task-info-fun-with-mach
  class Port
    include Functions

    class SendRightMsg < FFI::Struct
      include Functions

      layout(:header, MsgHeader,
             :body, MsgBody,
             :port, MsgPortDescriptor)
    end

    class ReceiveRightMsg < FFI::Struct
      include Functions

      layout(:header, MsgHeader,
             :body, MsgBody,
             :port, MsgPortDescriptor,
             :trailer, MsgTrailer)
    end

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
      @ipc_space = opts[:ipc_space] || mach_task_self
      right = opts[:right] || :receive

      @port = if opts[:port]
                opts[:port].to_i
              else
                mem = new_memory_pointer(:mach_port_right_t)
                mach_port_allocate(@ipc_space.to_i, right, mem)
                mem.get_uint(0)
              end
    end

    # With this alias, we can call #to_i on either bare Integer ports
    # or wrapped Port objects when passing the arg to a foreign
    # function.
    alias_method :to_i, :port

    def to_s
      "#<#{self.class} #{to_i}>"
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
      mach_port_deallocate(ipc_space.to_i, @port)
    end

    # Insert +right+ into another ipc space.  The current task must
    # have sufficient rights to insert the requested right.
    #
    # @param [MsgType] right
    #
    # @param [Hash] opts
    #
    # @option opts [Port,Integer] :ipc_space the space (task port) into which
    # +right+ will be inserted; defaults to this port's ipc_space
    #
    # @option opts [Port,Integer] :port the name the port right should
    # have in :ipc_space; defaults to the same name as this port
    def insert_right(right, opts = {})
      ipc_space = opts[:ipc_space] || @ipc_space
      port_name = opts[:port_name] || @port
      
      mach_port_insert_right(ipc_space.to_i, port_name.to_i, @port, right)
    end

    # Send +right+ on this Port to +remote_port+.  The current task
    # must already have the requisite rights allowing it to send
    # +right+.
    def send_right(right, remote_port)
      msg = SendRightMsg.new

      msg[:header].tap do |h|
        h[:remote_port] = remote_port.to_i
        h[:local_port] = PORT_NULL
        h[:bits] =
          (MsgType[right] | (0 << 8)) | 0x80000000 # MACH_MSGH_BITS_COMPLEX
        h[:size] = 40 # msg.size
      end

      msg[:body][:descriptor_count] = 1

      msg[:port].tap do |p|
        p[:name] = port
        p[:disposition] = MsgType[right]
        p[:type] = 0 # MSG_PORT_DESCRIPTOR;
      end
      
      mach_msg_send msg
    end

    # Copy the send right on this port and send it in a message to
    # +remote_port+.  The current task must have an existing send
    # right on this Port.
    def copy_send(remote_port)
      send_right(:copy_send, remote_port)
    end

    # Create a new Port by receiving a port right message on this
    # port.
    def receive_right
      msg = ReceiveRightMsg.new
  
      mach_msg(msg,
               2, # RCV_MSG,
               0,
               msg.size,
               port,
               MSG_TIMEOUT_NONE,
               PORT_NULL)

      self.class.new :port => msg[:port][:name]
    end
  end
end
