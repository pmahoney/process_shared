require 'ffi'

if VERSION =~ /^1.8/
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
require 'process_shared/bounded_semaphore'
require 'process_shared/mutex'
require 'process_shared/shared_memory'

