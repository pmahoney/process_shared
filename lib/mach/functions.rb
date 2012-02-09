require 'ffi'

require 'mach/types'
require 'mach/time_spec'

module Mach
  # FFI wrapper around a subset of the Mach API (likely Mac OS X
  # specific).
  module Functions
    extend FFI::Library
    extend Types

    ffi_lib 'c'

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
                          PortRight,
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
                          MsgType],
                         :kern_return_t)

    ##################
    # Host functions #
    ##################

    attach_function :mach_host_self, [], :mach_port_t

    attach_mach_function(:host_get_clock_service,
                         [:host_t,
                          :clock_id_t,
                          :pointer],
                         :kern_return_t)

    ##################
    # Task functions #
    ##################

    attach_mach_function(:task_get_special_port,
                         [:task_t,
                          SpecialPort,
                          :mach_port_pointer_t],
                         :kern_return_t)

    attach_mach_function(:task_set_special_port,
                         [:task_t,
                          SpecialPort,
                          :mach_port_t],
                         :kern_return_t)

    ###################
    # Clock functions #
    ###################

    attach_mach_function(:clock_get_time,
                         [:clock_id_t,
                          TimeSpec],
                         :kern_return_t)

    #####################
    # Message functions #
    #####################

    attach_mach_function(:mach_msg_send,
                         [:pointer], # msg_header_t
                         :kern_return_t)

    attach_mach_function(:mach_msg,
                         [:pointer, # msg_header_t
                          :mach_msg_option_t,
                          :mach_msg_size_t,
                          :mach_msg_size_t,
                          :mach_port_name_t,
                          :mach_msg_timeout_t,
                          :mach_port_name_t],
                         :kern_return_t)

    attach_mach_function(:mach_msg_receive,
                         [:pointer], # msg_header_t
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
                         [:semaphore_t, TimeSpec.val],
                         :kern_return_t)

  end
end

require 'mach/error'
