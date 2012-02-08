require 'mach'
require 'mach/error'

require 'process_shared/mach'
require 'process_shared/open_with_self'
require 'process_shared/synchronizable_semaphore'

module ProcessShared
  module Mach
    # Extends ::Mach::Semaphore to be compatible with ProcessShared::Semaphore
    class Semaphore < ::Mach::Semaphore
      extend ProcessShared::OpenWithSelf
      include ProcessShared::SynchronizableSemaphore

      def initialize(value = 1)
        super(:value => value)
        ProcessShared::Mach.shared_ports.add self
      end

      def try_wait(timeout = nil)
        secs = timeout ? timeout : 0
        begin
          # TODO catch and convert exceptions...
          timedwait(secs)
        rescue Mach::Error::OPERATION_TIMED_OUT => e
          klass = secs == 0 ? Errno::EAGAIN : Errno::ETIMEDOUT
          raise klass, e.message
        end
      end

      alias_method :post, :signal

      def value
        raise Errno::ENOTSUP
      end

      def close
        # TODO
      end
    end
  end
end
