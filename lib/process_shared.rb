require 'ffi'

if RUBY_VERSION =~ /^1.8/
  require 'process_shared/define_singleton_method'
  
  module ProcessShared
    module PSem
      extend DefineSingletonMethod
    end

    module RT
      extend DefineSingletonMethod
    end

    module LibC
      extend DefineSingletonMethod
    end
  end
end

require 'process_shared/semaphore'
require 'process_shared/binary_semaphore'
require 'process_shared/mutex'
require 'process_shared/shared_memory'

module ProcessShared
  case FFI::Platform::OS
  when 'linux'
    require 'process_shared/posix/shared_memory'
    require 'process_shared/posix/semaphore'

    SharedMemory.impl = Posix::SharedMemory
    Semaphore.impl = Posix::Semaphore
  when 'darwin'
    require 'process_shared/posix/shared_memory'
    require 'process_shared/mach/semaphore'

    SharedMemory.impl = Posix::SharedMemory
    Semaphore.impl = Mach::Semaphore
  end
end
