require 'ffi'

module ProcessShared
  module Posix
    module Errno
      extend FFI::Library

      ffi_lib FFI::Library::LIBC

      attach_variable :errno, :int

      # Replace methods in +syms+ with error checking wrappers that
      # invoke the original method and raise a {SystemCallError} with
      # the current errno if the return value is an error.
      #
      # Errors are detected if the block returns true when called with
      # the original method's return value.
      def error_check(*syms, &is_err)
        unless block_given?
          is_err = lambda { |v| (v == -1) }
        end

        syms.each do |sym|
          method = self.method(sym)
          new_method_body = proc do |*args|
            ret = method.call(*args)
            if is_err.call(ret)
              raise SystemCallError.new("error in #{sym}", Errno.errno)
            else
              ret
            end
          end

          define_singleton_method(sym, &new_method_body)
          define_method(sym, &new_method_body)
        end
      end
    end
  end
end
