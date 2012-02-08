module ProcessShared
  module OpenWithSelf
    # Like #new but if the optional code block is given, it will be
    # passed the new object as an argument, and the object will
    # automatically be closed (by invoking +close+) when the block
    # terminates. In this instance, value of the block is returned.
    def open(*args, &block)
      obj = new(*args)
      if block_given?
        begin
          yield obj
        ensure
          obj.close
        end
      else
        obj
      end
    end
  end
end
