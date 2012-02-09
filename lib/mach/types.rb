require 'ffi'

module Mach
  module Types
    extend FFI::Library

    typedef :__darwin_mach_port_t, :mach_port_t
    typedef :__darwin_natural_t, :natural_t

    typedef :int, :integer_t
    typedef :int, :kern_return_t # true for 64 bit??
    typedef :int, :mach_error_t
    typedef :int, :sync_policy_t # SyncPolicy
    typedef :int, :clock_id_t
    typedef :int, :clock_res_t

    typedef :string, :name_t

    typedef :mach_port_t, :host_t
    typedef :mach_port_t, :task_t
    typedef :mach_port_t, :ipc_space_t
    typedef :mach_port_t, :semaphore_t
    typedef :pointer, :mach_port_pointer_t

    typedef :natural_t, :mach_port_name_t
    typedef :natural_t, :mach_port_right_t # MachPortRight
    typedef :pointer, :mach_port_name_array_t
    typedef :pointer, :mach_port_name_pointer_t

    typedef :uint, :mach_msg_type_name_t
    typedef :uint, :mach_msg_bits_t
    typedef :uint, :mach_msg_trailer_type_t
    typedef :uint, :mach_msg_trailer_size_t
    typedef :uint, :mach_msg_descriptor_type_t
    typedef :natural_t, :mach_msg_timeout_t

    typedef :natural_t, :mach_msg_size_t
    typedef :integer_t, :mach_msg_id_t
    typedef :integer_t, :mach_msg_options_t
    typedef :integer_t, :mach_msg_option_t

    def self.typedefs
      @ffi_typedefs
    end

    def find_type(t)
      Mach::Types.find_type(t) || super
    end

    def enum(*args)
      Mach::Types.enum(*args)
    end
  end
end
