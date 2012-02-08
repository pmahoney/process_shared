require 'process_shared/shared_memory_io'

module ProcessShared
  # Provides reading and writing of serialized objects from a memory
  # buffer.
  module ObjectBuffer
    # Write the serialization of +obj+ (using Marshal.dump) to this
    # shared memory object at +offset+ (in bytes).
    #
    # Raises IndexError if there is insufficient space.
    def put_object(offset, obj)
      # FIXME: This is a workaround to an issue I'm seeing in
      # 1.8.7-p352 (not tested in other 1.8's).  If I used the code
      # below that works in 1.9, then inside SharedMemoryIO#write, the
      # passed string object is 'terminated' (garbage collected?) and
      # won't respond to any methods...  This way is less efficient
      # since it involves the creation of an intermediate string, but
      # it works in 1.8.7-p352.
      if RUBY_VERSION =~ /^1.8/
        str = Marshal.dump(obj)
        return put_bytes(offset, str, 0, str.size)
      end

      io = SharedMemoryIO.new(self)
      io.seek(offset)
      Marshal.dump(obj, io)
    end

    # Read the serialized object at +offset+ (in bytes) using
    # Marshal.load.
    #
    # @return [Object]
    def get_object(offset)
      io = to_shm_io
      io.seek(offset)
      Marshal.load(io)
    end

    # Equivalent to {#put_object(0, obj)}
    def write_object(obj)
      put_object(0, obj)
    end

    # Equivalent to {#read_object(0, obj)}
    #
    # @return [Object]
    def read_object
      Marshal.load(to_shm_io)
    end

    protected

    def to_shm_io
      SharedMemoryIO.new(self)
    end
  end
end
