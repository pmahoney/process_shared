require 'spec_helper'
require 'process_shared/bounded_semaphore'

module ProcessShared
  describe BoundedSemaphore do
    it 'never rises above its max value' do
      max = 10
      BoundedSemaphore.open(max) do |sem|
        pids = []
        10.times do |i|
          pids << fork do
            100.times do
              if rand(3) == 0
                sem.wait
              else
                sem.post
              end
            end

            exit i
          end
        end

        100.times do
          sem.value.must be_lte(max)
        end

        pids.each { |pid| Process.wait(pid) }
      end
    end

    describe '#post and #wait' do
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
end
