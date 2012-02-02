require 'mach/functions'
require 'mach/port'
require 'mach/host'
require 'mach/clock'

module Mach
  class Semaphore < Port
    include Functions

    # Create a new Semaphore.
    #
    # @param [Hash] opts
    #
    # @option opts [Integer] :value the initial value of the
    # semaphore; defaults to 1
    #
    # @option opts [Integer] :task the Mach task that owns the
    # semaphore (defaults to Mach.task_self)
    #
    # @options opts [Integer] :sync_policy the sync policy for this
    # semaphore (defaults to SyncPolicy::FIFO)
    #
    # @options opts [Integer] :port existing port to wrap with a
    # Semaphore object; otherwise a new semaphore is created
    #
    # @return [Integer] a semaphore port name
    def initialize(opts = {})
      value = opts[:value] || 1
      task = (opts[:task] && opts[:task].to_i) || ipc_space || mach_task_self
      sync_policy = opts[:sync_policy] || :fifo

      port = if opts[:port]
               opts[:port].to_i
             else
               mem = new_memory_pointer(:semaphore_t)
               semaphore_create(task, mem, sync_policy, value)
               mem.get_uint(0)
             end

      super(:port => port, :ipc_space => task)
    end

    # Destroy a Semaphore.
    #
    # @param [Hash] opts
    #
    # @option opts [Integer] :task the Mach task that owns the
    # semaphore (defaults to the owning task)
    def destroy(opts = {})
      task = opts[:task] || ipc_space || mach_task_self
      semaphore_destroy(task.to_i, port)
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

    # @see http://pkaudio.blogspot.com/2010/05/mac-os-x-no-timed-semaphore-waits.html
    def timedwait(secs)
      timespec = TimeSpec.new
      timespec.add_seconds!(secs)

      semaphore_timedwait(port, timespec)
    end
  end
end
