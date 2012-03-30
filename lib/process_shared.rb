require 'ffi'

if RUBY_VERSION =~ /^1.8/
  require 'process_shared/define_singleton_method'
  
  class Module
    include ProcessShared::DefineSingletonMethod
  end
end

module ProcessShared
  case FFI::Platform::OS
  when 'linux'
    require 'process_shared/posix/shared_memory'
    require 'process_shared/posix/semaphore'

    SharedMemory = Posix::SharedMemory
    Semaphore = Posix::Semaphore
  when 'darwin'
    require 'process_shared/posix/shared_memory'
    require 'process_shared/mach/semaphore'

    SharedMemory = Posix::SharedMemory
    Semaphore = Mach::Semaphore
  end
end

require 'process_shared/binary_semaphore'
require 'process_shared/mutex'
require 'process_shared/condition_variable'
require 'process_shared/monitor'
require 'process_shared/monitor_mixin'

