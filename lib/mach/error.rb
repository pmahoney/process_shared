require 'ffi'

require 'mach/functions'

module Mach
  class Error < StandardError
    class INVALID_ADDRESS < Error; end
    class PROTECTION_FAILURE < Error; end
    class NO_SPACE < Error; end
    class INVALID_ARGUMENT < Error; end
    class FAILURE < Error; end
    class ABORTED < Error; end
    class INVALID_NAME < Error; end
    class OPERATION_TIMED_OUT < Error; end

    include Functions

    def self.new(msg, errno)
      klass = case errno
              when 1; then INVALID_ADDRESS
              when 2; then PROTECTION_FAILURE
              when 3; then NO_SPACE
              when 4; then INVALID_ARGUMENT
              when 5; then FAILURE
              when 14; then ABORTED
              when 15; then INVALID_NAME
              when 49; then OPERATION_TIMED_OUT
              else FAILURE
              end

      e = klass.allocate
      e.send(:initialize, msg, errno)
      e
    end

    attr_reader :errno

    def initialize(msg, errno)
      super(msg)
      @errno = errno
    end

    def to_s
      "#{super}: #{error_string(errno)}"
    end

    protected

    # NOTE: api does not say this string must be freed; assuming it
    # does not
    def error_string(errno)
      ptr = mach_error_string(errno)
      ptr.null? ? nil : ptr.read_string()
    end
  end
end
