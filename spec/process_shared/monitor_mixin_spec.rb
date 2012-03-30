require 'spec_helper'
require 'process_shared'

module ProcessShared
  describe MonitorMixin do

    before :each do
      @obj = Object.new
      @obj.extend(MonitorMixin)
    end

    it 'raises exception when unlocked by other process' do
      pid = Kernel.fork do
        @obj.mon_enter
        sleep 0.2
        @obj.mon_exit
        Kernel.exit!
      end

      sleep 0.1
      proc { @obj.mon_exit }.must_raise(ProcessError)

      ::Process.wait(pid)
    end

    it 'raises nothing with nested lock' do
      @obj.mon_enter
      @obj.mon_enter
      @obj.mon_exit
      @obj.mon_exit
    end
  end
end
