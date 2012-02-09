require 'set'
require 'mach'

module ProcessShared
  module Mach
    include ::Mach

    # The set of ports that should be shared to forked child
    # processes.
    #
    # FIXME: protect with (original ruby) mutex?
    def self.shared_ports
      @shared_ports ||= Set.new
    end

    def self.after_fork_child
      parent_port = Task.self.get_bootstrap_port

      # give parent permission to send to child's task port
      Task.self.copy_send(parent_port)

      # create a second port and give the parent permission to send
      port = Port.new
      port.insert_right(:make_send)
      port.copy_send(parent_port)

      # parent copies sem, mutex port permissions directly to child
      # task port

      # wait for parent to send orig bootstrap port
      orig_bootstrap = port.receive_right
      Task.self.set_special_port(:bootstrap, orig_bootstrap)
    end

    def self.after_fork_parent(port)
      child_task_port = port.receive_right
      shared_ports.each do |p|
        p.insert_right(:copy_send, :ipc_space => child_task_port)
      end

      child_port = port.receive_right
      ::Mach::bootstrap_port.copy_send(child_port)
    end
  end
end

module Kernel
  # Override to call Process::fork.
  def self.fork(*args, &block)
    Process.fork(*args, &block)
  end

  def fork(*args, &block)
    Process.fork(*args, &block)
  end
end

module Process
  class << self
    unless respond_to? :__mach_original_fork__
      alias_method :__mach_original_fork__, :fork
    end

    # Override to first copy all shared ports (semaphores, etc.) from
    # parent process to child process.
    def fork
      # make a port for receiving message from child
      port = Mach::Port.new
      port.insert_right(:make_send)
      Mach::Task.self.set_bootstrap_port(port)
      
      if block_given?
        pid = __mach_original_fork__ do
          ProcessShared::Mach.after_fork_child
          yield
        end

        ProcessShared::Mach.after_fork_parent(port)
        pid
      else
        if pid = __mach_original_fork__
          ProcessShared::Mach.after_fork_parent(port)
          pid
        else
          ProcessShared::Mach.after_fork_child
          nil
        end
      end
    end
  end
end

require 'mach/time_spec'
require 'process_shared/time_spec'

# Monkey patch to add #add_seconds! method
Mach::TimeSpec.send(:include, ProcessShared::TimeSpec)
