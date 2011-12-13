# require 'process_shared/libc' - circular dependency here...

module ProcessShared
  module PosixCall
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
        define_singleton_method(sym) do |*args|
          ret = method.call(*args)
          if is_err.call(ret)
            raise SystemCallError.new("error in #{sym}", LibC.errno)
          else
            ret
          end
        end
      end
    end
  end
end
