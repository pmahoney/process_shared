require 'ffi'

require 'mach'
require 'mach/types'

module Mach
  module Bootstrap
    extend FFI::Library
    include Types

    ffi_lib 'c'

    attach_variable :port, :bootstrap_port, :mach_port_t

    attach_function(:bootstrap_strerror,
                    [:kern_return_t],
                    :pointer)

    attach_function(:register,
                    :bootstrap_register,
                    [:mach_port_t, :name_t, :mach_port_t],
                    :kern_return_t)

    error_check :register

    # NOTE: api does not say this string must be freed; assuming it
    # does not
    #
    # @return [String] the error string or nil
    def self.strerror(errno)
      ptr = bootstrap_strerror(errno)
      ptr.null? ? nil : ptr.read_string()
    end
  end
end
