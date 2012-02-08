require 'process_shared'

module ProcessShared
  class SharedArray < SharedMemory
    include Enumerable

    # A fixed-size array in shared memory.  Processes forked from this
    # one will be able to read and write shared data to the array.
    # Access should be synchronized using a {Mutex}, {Semaphore}, or
    # other means.
    #
    # Note that {Enumerable} methods such as {#map}, {#sort},
    # etc. return new {Array} objects rather than modifying the shared
    # array.
    #
    # @param [Symbol] type_or_count the data type as a symbol
    # understood by FFI (e.g. :int, :double)
    #
    # @param [Integer] count number of array elements
    def initialize(type_or_count = 1, count = 1)
      super(type_or_count, count)

      # See https://github.com/ffi/ffi/issues/118
      ffi_type = FFI.find_type(self.type)

      name = if ffi_type.inspect =~ /FFI::Type::Builtin:(\w+)*/
               # name will be something like int32
               $1.downcase
             end

      unless name
        raise ArgumentError, "could not find FFI::Type for #{self.type}"
      end
      
      getter = "get_#{name}"
      setter = "put_#{name}"

      # singleton class
      sclass = class << self; self; end

      unless sclass.method_defined?(getter)
        raise ArgumentError, "no element getter for #{self.type} (#{getter})"
      end

      unless sclass.method_defined?(setter)
        raise ArgumentError, "no element setter for #{self.type} (#{setter})"
      end

      sclass.send(:alias_method, :get_type, getter)
      sclass.send(:alias_method, :put_type, setter)
    end

    def each
      # NOTE: using @count because Enumerable defines its own count
      # method...
      @count.times { |i| yield self[i] }
    end

    def each_with_index
      @count.times { |i| yield self[i], i }
    end

    def [](i)
      get_type(i * self.type_size)
    end

    def []=(i, val)
      put_type(i * self.type_size, val)
    end
  end
end
