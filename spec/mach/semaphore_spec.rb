require 'spec_helper'
require 'mach'

module Mach
  describe 'low level semaphore functions' do
    include Functions

    it 'raises exception with invalid args' do
      p = proc { semaphore_create(mach_task_self, nil, 1234, 1) }
      p.must_raise Error::INVALID_ARGUMENT
    end
  end

  describe Semaphore do
    it 'creates a semaphore' do
      sem = Semaphore.new
      sem.destroy
    end

    it 'raises exception with invalid args' do
      p = proc { Semaphore.new(:sync_policy => :no_such) }
      p.must_raise ArgumentError # Error::INVALID_ARGUMENT
    end

    it 'signals/waits in same task' do
      sem = Semaphore.new(:value => 0)
      sem.signal
      sem.wait
      sem.destroy
    end

    it 'coordinates access to shared resource between two tasks' do
      begin
        sem = Semaphore.new(:value => 0)

        port = Port.new
        port.insert_right(:make_send)
        Task.self.set_bootstrap_port(port)

        method = if Process.respond_to?(:__mach_original_fork__)
                   :__mach_original_fork__
                 else
                   :fork
                 end

        child = Process.send(method) do
          parent_port = Task.self.get_bootstrap_port
          Task.self.copy_send(parent_port)
          # parent will copy send rights to sem into child task
          sleep 0.5
          sem.signal
          Kernel.exit!
        end

        child_task_port = port.receive_right

        start = Time.now.to_f
        sem.insert_right(:copy_send, :ipc_space => child_task_port)
        sem.timedwait(1)
        elapsed = Time.now.to_f - start

        Process.wait child

        elapsed.must be_gt(0.4)
      ensure
        Task.self.set_bootstrap_port(Mach::Functions.bootstrap_port)
      end
    end
  end
end
