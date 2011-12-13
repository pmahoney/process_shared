module ProcessShared
  module DefineSingletonMethod
    # This method was added in Ruby 1.9.x.  Include this module for
    # backwards compatibility.
    #
    # This isn't exactly compatible with the method in 1.9 which can
    # take a Proc, Method, or a block.  This only accepts a block.
    def define_singleton_method(sym, &block)
      eigenclass = class << self; self; end
      eigenclass.send(:define_method, sym, &block)
    end
  end
end

