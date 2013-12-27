# encoding: UTF-8
# ^^^
# NOTE: This magic comment is necessary for the UTF-8 string literal below
#       on Ruby 1.9.x
require 'spec_helper'
require 'process_shared'

module ProcessShared
  describe SharedMemoryIO do

    describe '#read' do
      def binary(s)
        (RUBY_VERSION == '1.8.7') ? s : s.force_encoding('ASCII-8BIT')
      end

      def output_for(input)
        mem = SharedMemory.new(16)
        mem.put_bytes(0, input, 0, input.bytesize)
        io = SharedMemoryIO.new(mem)
        io.read(input.bytesize)
      end

      it 'returns correct binary data for plain ASCII string' do
        input = 'Hello'
        output_for(input).must_equal binary(input)
      end

      it 'returns correct binary data for UTF-8 string' do
        input = 'Mária'
        output_for(input).must_equal binary(input)
      end

      it 'returns correct binary data for explicitly binary data' do
        input = "\x00\xD1\x9B\x86\x00"
        output_for(input).must_equal binary(input)
      end
    end

  end
end
