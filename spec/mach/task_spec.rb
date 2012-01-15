require 'spec_helper'
require 'mach'
require 'mach/port'
require 'mach/task'

module Mach
  describe Task do
    before :each do
      @task = Task.self
    end

    it 'gets special ports' do
      bp = @task.get_special_port(:bootstrap)
      bp.must_equal @task.get_bootstrap_port
    end

    it 'redefines bootstrap port' do
      bp = @task.get_bootstrap_port
      new_bp = Port.new
      bp.wont_equal(new_bp)

      begin
        new_bp.insert_right(:make_send)
        @task.set_bootstrap_port(new_bp)
        @task.get_bootstrap_port.must_equal(new_bp)
      ensure
        @task.set_bootstrap_port(bp)
      end
    end
  end
end
