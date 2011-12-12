require 'spec_helper'
require 'process_shared/mutex'
require 'process_shared/shared_memory'

module ProcessShared
  describe Mutex do
    it 'protects access to a shared variable' do
      mutex = Mutex.new
      mem = SharedMemory.new(:char)
      mem.put_char(0, 0)

      pids = []
      10.times do |i|
        inc = (-1) ** i         # half the procs increment; half decrement
        pids << fork do
          10.times do
            mutex.lock
            begin
              mem.put_char(0, mem.get_char(0) + inc)
              sleep 0.001
            ensure
              mutex.unlock
            end
          end
          Kernel.exit!
        end
      end

      pids.each { |pid| ::Process.wait(pid) }

      mem.get_char(0).must_equal(0)
    end

    it 'protects access to a shared variable with synchronize' do
      mutex = Mutex.new
      mem = SharedMemory.new(:char)
      mem.put_char(0, 0)

      pids = []
      10.times do |i|
        inc = (-1) ** i         # half the procs increment; half decrement
        pids << fork do
          10.times do
            mutex.synchronize do
              mem.put_char(0, mem.get_char(0) + inc)
              sleep 0.001
            end
          end
          Kernel.exit!
        end
      end

      pids.each { |pid| ::Process.wait(pid) }

      mem.get_char(0).must_equal(0)
    end

    it 'raises exception when unlocked by other process' do
      mutex = Mutex.new

      pid = Kernel.fork do
        mutex.lock
        sleep 0.2
        mutex.unlock
        Kernel.exit!
      end

      sleep 0.1
      proc { mutex.unlock }.must_raise(ProcessError)

      ::Process.wait(pid)
    end

    it 'raises exception when locked twice by same process' do
      mutex = Mutex.new

      mutex.lock
      proc { mutex.lock }.must_raise(ProcessError)
      mutex.unlock
    end
  end
end
