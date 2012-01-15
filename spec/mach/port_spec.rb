require 'spec_helper'
require 'mach/port'

module Mach
  describe Port do
    it 'creates a port' do
      port = Port.new
      port.destroy
    end

    it 'raises exception with invalid args' do
      p = proc { Port.new(:right => 1234) }
      p.must_raise Error::FAILURE
    end

    it 'inserts rights' do
      port = Port.new
      port.insert_right(:make_send)
    end
  end
end
