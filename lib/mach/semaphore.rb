require 'mach/functions'
require 'mach/port'

module Mach
  class Semaphore < Port
    include Functions

    # Create a new Semaphore.
    #
    # @param [Integer] value the initial value of the semaphore
    #
    # @param [Hash] opts
    #
    # @option opts [Integer] :task the Mach task that owns the
    # semaphore (defaults to Mach.task_self)
    #
    # @options opts [Integer] :sync_policy the sync policy for this
    # semaphore (defaults to SyncPolicy::FIFO)
    #
    # @return [Integer] a semaphore port name
    def initialize(value = 1, opts = {})
      task = opts[:task] || ipc_space || mach_task_self
      sync_policy = opts[:sync_policy] || :fifo

      mem = new_memory_pointer(:semaphore_t)
      semaphore_create(task, mem, sync_policy, value)
      super(mem.get_uint(0), :ipc_space => task)
    end

    # Destroy a Semaphore.
    #
    # @param [Hash] opts
    #
    # @option opts [Integer] :task the Mach task that owns the
    # semaphore (defaults to the owning task)
    def destroy(opts = {})
      task = opts[:task] || ipc_space || mach_task_self
      semaphore_destroy(task, port)
    end

    def signal
      semaphore_signal(port)
    end

    def signal_all
      semaphore_signal_all(port)
    end

    def wait
      semaphore_wait(port)
    end

    # TODO: implement
    def timedwait(secs)
      semaphore_timedwait(port, timespec)
    end
  end
end
