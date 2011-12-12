require 'process_shared/libc'

module ProcessShared
  describe LibC do
    it 'throws exceptions with invalid args' do
      proc { LibC.mmap nil,2,0,0,1,0 }.must_raise(Errno::EINVAL)
    end
  end
end
