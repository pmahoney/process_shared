require 'process_shared'

module ProcessShared
  module MonitorMixin
    def self.extended(obj)
      obj.send :mon_initialize
    end

    def mon_enter
      @mon_monitor.lock
    end
    
    def mon_exit
      @mon_monitor.unlock
    end
    
    def mon_synchronize
      mon_enter
      begin
        yield
      ensure
        mon_exit
      end
    end
    alias_method :synchronize, :mon_synchronize
    
    def mon_try_enter
      raise NotImplementedError, 'not implemented'
    end
    alias_method :try_mon_enter, :mon_try_enter
    
    def new_cond
      raise NotImplementedError, 'not implemented'
    end

    private

    def mon_initialize
      @mon_monitor = Monitor.new
    end
  end
end
