module Mach
  # FFI wrapper around a subset of the Mach API (likely Mac OS X
  # specific).
  module Functions
    extend FFI::Library

    ffi_lib 'c'

    typedef :__darwin_mach_port_t, :mach_port_t
    typedef :__darwin_natural_t, :natural_t

    typedef :mach_port_t, :task_t
    typedef :mach_port_t, :ipc_space_t
    typedef :mach_port_t, :semaphore_t
    typedef :pointer, :mach_port_pointer_t

    typedef :natural_t, :mach_port_name_t
    typedef :natural_t, :mach_port_right_t # MachPortRight
    typedef :pointer, :mach_port_name_array_t
    typedef :pointer, :mach_port_name_pointer_t

    typedef :uint, :mach_msg_type_name_t

    typedef :int, :kern_return_t # true for 64 bit??
    typedef :int, :mach_error_t
    typedef :int, :sync_policy_t # SyncPolicy

    typedef :string, :name_t

    SyncPolicy = enum( :fifo, 0x0,
                       :fixed_priority, 0x1,
                       :reversed, 0x2,
                       :order_mask, 0x3,
                       :lifo, 0x0 | 0x2, # um...
                       :max, 0x7 )

    MachPortRight = enum( :send, 0,
                          :receive,
                          :send_once,
                          :port_set,
                          :dead_name,
                          :labelh,
                          :number )

    # port type
    def self.pt(*syms)
      acc = 0
      syms.each do |sym|
        acc |= (1 << (MachPortRight[sym] + 16))
      end
      acc
    end
    
    MachPortType =
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

    MachMsgType =
      enum( :move_receive, 16, # must hold receive rights
            :move_send,        # must hold send rights
            :move_send_once,   # must hold sendonce rights
            :copy_send,        # must hold send rights
            :make_send,        # must hold receive rights
            :make_send_once,   # must hold receive rights
            :copy_receive )    # must hold receive rights

    MachSpecialPort =
      enum( :kernel, 1,
            :host,
            :name,
            :bootstrap )

    class Timespec < FFI::ManagedStruct
      layout(:tv_sec, :uint,
             :tv_nsec, :int)
    end

    KERN_SUCCESS = 0

    # Replace methods in +syms+ with error checking wrappers that
    # invoke the original method and raise a {SystemCallError}.
    #
    # The original method is invoked, and it's return value is passed
    # to the block (or a default check).  The block should return true
    # if the return value indicates an error state.
    def self.error_check(*syms, &is_err)
      unless block_given?
        is_err = lambda { |v| (v != KERN_SUCCESS) }
      end

      syms.each do |sym|
        method = self.method(sym)

        new_method_body = proc do |*args|
          ret = method.call(*args)
          if is_err.call(ret)
            raise Error.new("error in #{sym}", ret)
          else
            ret
          end
        end

        define_singleton_method(sym, &new_method_body)
        define_method(sym, &new_method_body)
       end
    end

    # Replace methods in +syms+ with error checking wrappers that
    # invoke the original method and raise a {SystemCallError}.
    #
    # The original method is invoked, and it's return value is passed
    # to the block (or a default check).  The block should return true
    # if the return value indicates an error state.
    def self.error_check_bootstrap(*syms, &is_err)
      unless block_given?
        is_err = lambda { |v| (v != KERN_SUCCESS) }
      end

      syms.each do |sym|
        method = self.method(sym)

        new_method_body = proc do |*args|
          ret = method.call(*args)
          if is_err.call(ret)
            ptr = bootstrap_strerror(ret)
            msg = ptr.null? ? nil : ptr.read_string()
            raise "error in #{sym}: #{msg}"
          else
            ret
          end
        end
        
        define_singleton_method(sym, &new_method_body)
        define_method(sym, &new_method_body)
      end
    end

    # Attach a function as with +attach_function+, but check the
    # return value and raise an exception on errors.
    def self.attach_mach_function(sym, argtypes, rettype)
      attach_function(sym, argtypes, rettype)
      error_check(sym)
    end

    def self.new_memory_pointer(type)
      FFI::MemoryPointer.new(find_type(type))
    end

    def new_memory_pointer(type)
      Mach::Functions.new_memory_pointer(type)
    end

    attach_function :mach_task_self, [], :task_t
    attach_function :mach_error_string, [:mach_error_t], :pointer

    #######################
    # Bootstrap functions #
    #######################

    attach_variable :bootstrap_port, :mach_port_t

    attach_function(:bootstrap_strerror,
                    [:kern_return_t],
                    :pointer)

    attach_function(:bootstrap_register,
                    [:mach_port_t, :name_t, :mach_port_t],
                    :kern_return_t)
    error_check_bootstrap :bootstrap_register

    ##################
    # Port functions #
    ##################

    attach_mach_function(:mach_port_allocate,
                         [:ipc_space_t,
                          MachPortRight,
                          :mach_port_name_pointer_t],
                         :kern_return_t)
    
    attach_mach_function(:mach_port_destroy,
                         [:ipc_space_t,
                          :mach_port_name_t],
                         :kern_return_t)
    
    attach_mach_function(:mach_port_deallocate,
                         [:ipc_space_t,
                          :mach_port_name_t],
                         :kern_return_t)
    
    attach_mach_function(:mach_port_insert_right,
                         [:ipc_space_t,
                          :mach_port_name_t,
                          :mach_port_t,
                          MachMsgType],
                         :kern_return_t)

    ##################
    # Task functions #
    ##################

    attach_mach_function(:task_get_special_port,
                         [:task_t,
                          :int,
                          :mach_port_pointer_t],
                         :kern_return_t)

    attach_mach_function(:task_set_special_port,
                         [:task_t,
                          :int,
                          :mach_port_t],
                         :kern_return_t)

    #######################
    # Semaphore functions #
    #######################

    attach_mach_function(:semaphore_create,
                         [:task_t, :pointer, SyncPolicy, :int],
                         :kern_return_t)
    attach_mach_function(:semaphore_destroy,
                         [:task_t, :semaphore_t],
                         :kern_return_t)

    attach_mach_function(:semaphore_signal,
                         [:semaphore_t],
                         :kern_return_t)
    attach_mach_function(:semaphore_signal_all,
                         [:semaphore_t],
                         :kern_return_t)
    attach_mach_function(:semaphore_wait,
                         [:semaphore_t],
                         :kern_return_t)
    attach_mach_function(:semaphore_timedwait,
                         [:semaphore_t, Timespec.val],
                         :kern_return_t)

  end
end

require 'mach/error'
