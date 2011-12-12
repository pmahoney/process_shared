require 'spec_helper'
require 'process_shared/psem'

module ProcessShared
  describe PSem do
    before do
      extend PSem
    end

    before(:each) do
      @err = FFI::MemoryPointer.new(:pointer)
    end

    describe '.psem_open' do
      it 'opens a psem' do
        psem = FFI::MemoryPointer.new(PSem.sizeof_psem_t)
        psem_open(psem, "psem-test", 1, @err)
        psem_unlink("psem-test", @err)
      end

      it 'raises excpetion if name alredy exists' do
        psem1 = FFI::MemoryPointer.new(PSem.sizeof_psem_t)
        psem2 = FFI::MemoryPointer.new(PSem.sizeof_psem_t)
        psem_open(psem1, "psem-test", 1, @err)
        proc { psem_open(psem2, "psem-test", 1, @err) }.must_raise(Errno::EEXIST)

        psem_unlink("psem-test", @err)
        psem_open(psem2, "psem-test", 1, @err)
        psem_unlink("psem-test", @err)
      end
    end

    describe '.psem_wait' do
      before(:each) do
        @psem = FFI::MemoryPointer.new(PSem.sizeof_psem_t)
        psem_open(@psem, 'psem-test', 1, @err)
        psem_unlink('psem-test', @err)

        @int = FFI::MemoryPointer.new(:int)
      end

      after(:each) do
        #psem_close(@psem, @err)
      end

      def value
        psem_getvalue(@psem, @int, @err)
        @int.get_int(0)
      end

      it 'decrements psem value' do
        value.must_equal 1
        psem_wait(@psem, @err)
        value.must_equal(0)
      end

      it 'waits until another process posts' do
        psem_wait(@psem, @err)

        # child exits with ~ time spent waiting
        child = fork do
          start = Time.now
          psem_wait(@psem, @err)
          exit (Time.now - start).ceil
        end

        t = 1.5
        sleep t
        psem_post(@psem, @err)
        _pid, status = Process.wait2(child)
        status.exitstatus.must_equal 2
      end
    end

    describe '.bsem_open' do
      it 'opens a bsem' do
        bsem = FFI::MemoryPointer.new(PSem.sizeof_bsem_t)
        bsem_open(bsem, "bsem-test", 1, 1, @err)
        bsem_unlink("bsem-test", @err)
      end

      it 'raises excpetion if name alredy exists' do
        bsem1 = FFI::MemoryPointer.new(PSem.sizeof_bsem_t)
        bsem2 = FFI::MemoryPointer.new(PSem.sizeof_bsem_t)
        bsem_open(bsem1, "bsem-test", 1, 1, @err)
        proc { bsem_open(bsem2, "bsem-test", 1, 1, @err) }.must_raise(Errno::EEXIST)

        bsem_unlink("bsem-test", @err)
        bsem_open(bsem2, "bsem-test", 1, 1, @err)
        bsem_unlink("bsem-test", @err)
      end
    end

    describe '.bsem_wait' do
      before(:each) do
        @bsem = FFI::MemoryPointer.new(PSem.sizeof_bsem_t)
        bsem_open(@bsem, 'bsem-test', 1, 1, @err)
        bsem_unlink('bsem-test', @err)

        @int = FFI::MemoryPointer.new(:int)
      end

      after do
        #bsem_close(@bsem, @err)
      end

      def value
        bsem_getvalue(@bsem, @int, @err)
        @int.get_int(0)
      end

      it 'decrements bsem value' do
        value.must_equal 1
        bsem_wait(@bsem, @err)
        value.must_equal 0
      end

      it 'waits until another process posts' do
        bsem_wait(@bsem, @err)

        # child exits with ~ time spent waiting
        child = fork do
          start = Time.now
          bsem_wait(@bsem, @err)
          exit (Time.now - start).ceil
        end

        t = 1.5
        sleep t
        bsem_post(@bsem, @err)
        _pid, status = Process.wait2(child)
        status.exitstatus.must_equal 2
      end
    end
  end
end
