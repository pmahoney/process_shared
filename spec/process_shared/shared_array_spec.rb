require 'spec_helper'
require 'process_shared/shared_array'

module ProcessShared
  describe SharedArray do
    it 'initializes arrays' do
      mem = SharedArray.new(:int, 10)
      10.times do |i|
        mem[i] = i
      end
      10.times do |i|
        mem[i].must_equal i
      end
    end

    it 'responds to Enumerable methods' do
      mem = SharedArray.new(:int, 4)
      4.times do |i|
        mem[i] = i+1
      end

      mem.map { |i| i * 2 }.must_equal [2, 4, 6, 8]
      mem.sort.must_equal [1, 2, 3, 4]
    end
  end
end
