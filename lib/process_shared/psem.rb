require 'ffi'

module ProcessShared
  module PSem
    class Error < FFI::Struct
      layout(:source, :int,
             :errno, :int)
    end

    extend FFI::Library

    # Workaround FFI dylib/bundle issue.  See https://github.com/ffi/ffi/issues/42
    suffix = if FFI::Platform.mac?
               'bundle'
             else
               FFI::Platform::LIBSUFFIX
             end

    ffi_lib File.join(File.expand_path(File.dirname(__FILE__)),
                      'libpsem.' + suffix)

    class << self
      # Replace methods in `syms` with error checking wrappers that
      # invoke the original psem method and raise an appropriate
      # error.
      def psem_error_check(*syms)
        syms.each do |sym|
          method = self.method(sym)

          block = lambda do |*args|
            if method.call(*args) < 0
              errp = args[-1]
              unless errp.nil?
                begin
                  err = Error.new(errp.get_pointer(0))
                  if err[:source] == PSem.e_source_system
                    raise SystemCallError.new("error in #{sym}", err[:errno])
                  else
                    raise "error in #{sym}: #{err.get_integer(1)}"
                  end
                ensure
                  psem_error_free(err)
                end
              end
            end
          end

          define_method(sym, &block)
          define_singleton_method(sym, &block)
        end
      end
    end

    # Generic constants

    int_consts = [:o_rdwr,
                  :o_creat,
                  :o_excl,
                  
                  :prot_read,
                  :prot_write,
                  :prot_exec,
                  :prot_none,
                  
                  :map_shared,
                  :map_private]
    int_consts.each { |sym| attach_variable sym, :int }

    # Other constants, functions

    attach_function :psem_error_free, :error_free, [:pointer], :void

    attach_variable :e_source_system, :E_SOURCE_SYSTEM, :int
    attach_variable :e_source_psem, :E_SOURCE_PSEM, :int

    attach_variable :e_name_too_long, :E_NAME_TOO_LONG, :int

    attach_variable :sizeof_psem_t, :size_t
    attach_variable :sizeof_bsem_t, :size_t

    # PSem functions

    attach_function :psem_open, [:pointer, :string, :uint, :pointer], :int
    attach_function :psem_close, [:pointer, :pointer], :int
    attach_function :psem_unlink, [:string, :pointer], :int
    attach_function :psem_post, [:pointer, :pointer], :int
    attach_function :psem_wait, [:pointer, :pointer], :int
    attach_function :psem_trywait, [:pointer, :pointer], :int
    attach_function :psem_timedwait, [:pointer, :pointer, :pointer], :int
    attach_function :psem_getvalue, [:pointer, :pointer, :pointer], :int

    psem_error_check(:psem_open, :psem_close, :psem_unlink, :psem_post,
                     :psem_wait, :psem_trywait, :psem_timedwait, :psem_getvalue)

    # BSem functions
    
    attach_function :bsem_open, [:pointer, :string, :uint, :uint, :pointer], :int
    attach_function :bsem_close, [:pointer, :pointer], :int
    attach_function :bsem_unlink, [:string, :pointer], :int
    attach_function :bsem_post, [:pointer, :pointer], :int
    attach_function :bsem_wait, [:pointer, :pointer], :int
    attach_function :bsem_trywait, [:pointer, :pointer], :int
    attach_function :bsem_timedwait, [:pointer, :pointer, :pointer], :int
    attach_function :bsem_getvalue, [:pointer, :pointer, :pointer], :int

    psem_error_check(:bsem_open, :bsem_close, :bsem_unlink, :bsem_post,
                     :bsem_wait, :bsem_trywait, :bsem_timedwait, :bsem_getvalue)
  end
end
