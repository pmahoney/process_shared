require 'ffi'

require 'mach/types'

module Mach
  extend Mach::Types

  class MsgHeader < FFI::Struct
    layout(:bits, :mach_msg_bits_t,
           :size, :mach_msg_size_t,
           :remote_port, :mach_port_t,
           :local_port, :mach_port_t,
           :reserved, :mach_msg_size_t,
           :id, :mach_msg_id_t)
  end

  class MsgBody < FFI::Struct
    layout(:descriptor_count, :mach_msg_size_t)
  end

  class MsgBase < FFI::Struct
    layout(:header, MsgHeader,
           :body, MsgBody)
  end

  class MsgTrailer < FFI::Struct
    layout(:type, :mach_msg_trailer_type_t,
           :size, :mach_msg_trailer_size_t)
  end

  class MsgPortDescriptor < FFI::Struct
    layout(:name, :mach_port_t,
           :pad1, :mach_msg_size_t, # FIXME: leave oout on __LP64__
           :pad2, :uint16, # :uint
           :disposition, :uint8, # :mach_msg_type_name_t
           :type, :uint8) # :mach_msg_descriptor_type_t
  end

  SyncPolicy = enum( :fifo, 0x0,
                     :fixed_priority, 0x1,
                     :reversed, 0x2,
                     :order_mask, 0x3,
                     :lifo, 0x0 | 0x2, # um...
                     :max, 0x7 )

  PortRight = enum( :send, 0,
                    :receive,
                    :send_once,
                    :port_set,
                    :dead_name,
                    :labelh,
                    :number )

  # port type macro
  def self.pt(*syms)
    acc = 0
    syms.each do |sym|
      acc |= (1 << (PortRight[sym] + 16))
    end
    acc
  end

  PORT_NULL = 0
  MSG_TIMEOUT_NONE = 0
  
  PortType =
    enum(:none, 0,
         :send, pt(:send),
         :receive, pt(:receive),
         :send_once, pt(:send_once),
         :port_set, pt(:port_set),
         :dead_name, pt(:dead_name),
         :labelh, pt(:labelh),
         
         :send_receive, pt(:send, :receive),
         :send_rights, pt(:send, :send_once),
         :port_rights, pt(:send, :send_once, :receive),
         :port_or_dead, pt(:send, :send_once, :receive, :dead_name),
         :all_rights, pt(:send, :send_once, :receive, :dead_name, :port_set))

  MsgType =
    enum( :move_receive, 16, # must hold receive rights
          :move_send,        # must hold send rights
          :move_send_once,   # must hold sendonce rights
          :copy_send,        # must hold send rights
          :make_send,        # must hold receive rights
          :make_send_once,   # must hold receive rights
          :copy_receive )    # must hold receive rights

  SpecialPort =
    enum( :kernel, 1,
          :host,
          :name,
          :bootstrap )

  KERN_SUCCESS = 0


  # @return [Port] the original bootstrap port; different from that
  # affected by {get,set}_special_port
  def self.bootstrap_port
    @bootstrap_port ||= Mach::Port.new(:port => Mach::Functions::bootstrap_port)
  end
end

require 'mach/port'
require 'mach/semaphore'
require 'mach/task'
require 'mach/functions'
