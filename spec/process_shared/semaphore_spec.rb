require 'spec_helper'

require 'ffi'
require 'process_shared'

module ProcessShared
  describe Semaphore do

    describe 'As Lock' do

      include LockBehavior

      before :each do
        @lock = Semaphore.new
        class << @lock
          alias_method :lock, :wait
          alias_method :unlock, :post
        end
      end

      after :each do
        @lock.close
      end

    end

    it 'coordinates access to shared object' do
      nprocs = 4               # number of processes
      nincrs = 1000            # each process increments nincrs times

      do_increments = lambda do |mem, sem|
        nincrs.times do
          sem.wait
          begin
            val = mem.get_int(0)
            # ensure other procs have a chance to interfere
            sleep 0.002 if rand(50) == 0
            mem.put_int(0, val + 1)
          rescue => e
            "#{Process.pid} die'ing because #{e}"
          ensure
            sem.post
          end
        end
      end

      # Make sure it fails with no synchronization
      no_sem = Object.new
      class << no_sem
        def wait; end
        def post; end
      end
      SharedMemory.open(FFI.type_size(:int)) do |mem|
        pids = []
        nprocs.times do
          pids << fork { do_increments.call(mem, no_sem); exit }
        end
        
        pids.each { |p| Process.wait(p) }
        # puts "mem is #{mem.get_int(0)}"
        mem.get_int(0).must be_lt(nprocs * nincrs)
      end

      # Now try with synchronization
      SharedMemory.open(FFI.type_size(:int)) do |mem|
        pids = []
        Semaphore.open do |sem|
          nprocs.times do
            pids << fork { do_increments.call(mem, sem); exit }
          end
        end
        
        pids.each { |p| Process.wait(p) }
        mem.get_int(0).must_equal(nprocs * nincrs)
      end
    end

    describe '#post and #wait' do
      unless FFI::Platform.mac?
        it 'increments and decrements the value' do
          Semaphore.open(0) do |sem|
            10.times do |i|
              sem.post
              sem.value.must_equal(i + 1)
            end

            10.times do |i|
              sem.wait
              sem.value.must_equal(10 - i - 1)
            end
          end
        end
      end
    end

    describe '#try_wait' do
      it 'returns immediately with non-zero semaphore' do
        Semaphore.open(1) do |sem|
          start = Time.now.to_f
          sem.try_wait
          (Time.now.to_f - start).must be_lt(0.01)
        end
      end

      it 'raises EAGAIN with zero semaphore' do
        Semaphore.open(0) do |sem|
          proc { sem.try_wait }.must_raise(Errno::EAGAIN)
        end
      end

      it 'raises ETIMEDOUT after timeout expires' do
        Semaphore.open(0) do |sem|
          start = Time.now.to_f
          proc { sem.try_wait(0.1) }.must_raise(Errno::ETIMEDOUT)
          (Time.now.to_f - start).must be_gte(0.1)
        end
      end

      it 'returns after waiting if another processes posts' do
        Semaphore.open(0) do |sem|
          pid = fork do
            sleep 0.01
            sem.post
            Kernel.exit!
          end

          start = Time.now.to_f
          sem.try_wait(0.1)
          (Time.now.to_f - start).must be_lt(0.1)

          ::Process.wait(pid)
        end
      end
    end
  end
end
