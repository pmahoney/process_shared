require 'process_shared/psem'
require 'process_shared/with_self'

module ProcessShared
  class AbstractSemaphore
    include WithSelf
    protected
    include ProcessShared::PSem
    public

    # Generate a name for a semaphore.  If +name+ is given, it is used
    # as the name (and so a semaphore could be shared by arbitrary
    # processes not forked from one another).  Otherwise, a name is
    # generated containing +middle+ and the process id.
    #
    # @param [String] middle arbitrary string used in the middle
    # @param [String] name if given, used as the name
    # @return [String] name, or the generated name
    def self.gen_name(middle, name = nil)
      if name
        name
      else
        @count ||= 0
        @count += 1
        "ps-#{middle}-#{::Process.pid}-#{@count}"
      end
    end

    # Make a Proc suitable for use as a finalizer that will call
    # +psem_unlink+ on +name+ and ignore system errors.
    #
    # @return [Proc] a finalizer
    def self.make_finalizer(name)
      proc { ProcessShared::PSem.psem_unlink(name, nil) }
    end

    # private_class_method :new

    def synchronize
      wait
      begin
        yield
      ensure
        post
      end
    end

    protected

    attr_reader :sem, :err

    def init(size, middle, name, &block)
      @sem = FFI::MemoryPointer.new(size)
      @err = FFI::MemoryPointer.new(:pointer)
      psem_name = AbstractSemaphore.gen_name(middle, name)
      block.call(psem_name)

     if name
        # name explicitly given.  Don't unlink because we might want to share it with another process.
        # Instead, register a finalizer to unlink.
        ObjectSpace.define_finalizer(self, self.class.make_finalizer(name))
      else
        # On Linux, removes the entry in /dev/shm and prevents other
        # processes from opening this semaphore unless they inherit it
        # as forked children.
        psem_unlink(psem_name, err) unless name
      end
    end
  end
end
