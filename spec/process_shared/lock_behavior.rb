module ProcessShared
  # Classes that include this module should assign a lock object to
  # @lock before each test.
  module LockBehavior

    # Fork +n+ processes.  In each, yield the block (passing the process
    # number), then call Kernel.exit!  Waits for all processes to
    # complete before returning.
    def fork_many(n)
      pids = []
      n.times do |i|
        pids << fork do
          yield i
          Kernel.exit!
        end
      end

      pids.each { |pid| ::Process.wait(pid) }
    end

    def test_protects_access_to_a_shared_variable
      mem = SharedMemory.new(:char)
      mem.put_char(0, 0)

      fork_many(10) do |i|
        inc = (-1) ** i       # half the procs increment; half decrement
        10.times do
          @lock.lock
          begin
            mem.put_char(0, mem.get_char(0) + inc)
            sleep 0.001
          ensure
            @lock.unlock
          end
        end
      end

      mem.get_char(0).must_equal(0)
    end

    def test_protects_access_to_a_shared_variable_with_synchronize
      mem = SharedMemory.new(:char)
      mem.put_char(0, 0)

      fork_many(10) do |i|
        inc = (-1) ** i         # half the procs increment; half decrement
        10.times do
          @lock.synchronize do
            mem.put_char(0, mem.get_char(0) + inc)
            sleep 0.001
          end
        end
      end

      mem.get_char(0).must_equal(0)
    end


  end
end
