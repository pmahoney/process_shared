require 'mach/port'
require 'mach/semaphore'
require 'mach/task'
require 'mach/functions'

module Mach
  # @return [Port] the original bootstrap port; different from that
  # affected by {get,set}_special_port
  def self.bootstrap_port
    @bootstrap_port ||= Mach::Port.new(:port => Mach::Functions::bootstrap_port)
  end
end
