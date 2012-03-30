require 'process_shared'
require 'process_shared/mutex'

module ProcessShared
  class Monitor < Mutex
    def initialize
      super
      @lock_count = 0
    end

    def lock
      if locked_by == ::Process.pid
        @lock_count += 1
      else
        super
      end
    end

    def unlock
      if locked_by == ::Process.pid
        if @lock_count > 0
          @lock_count -= 1
        else
          super
        end
      else
        super
      end
    end
  end
end
