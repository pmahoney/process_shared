module ProcessShared
  module WithSelf
    # With no associated block, return self.  If the optional code
    # block is given, it will be passed `self` as an argument, and the
    # self object will automatically be closed (by invoking `close` on
    # `self`) when the block terminates. In this instance, value of
    # the block is returned.
    def with_self
      if block_given?
        begin
          yield self
        ensure
          self.close
        end
      else
        self
      end
    end
  end
end
