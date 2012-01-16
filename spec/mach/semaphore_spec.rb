require 'spec_helper'
require 'mach/error'
require 'mach/functions'
require 'mach/semaphore'

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
  end
end
