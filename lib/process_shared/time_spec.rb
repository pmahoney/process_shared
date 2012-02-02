module ProcessShared
  module TimeSpec
    NS_PER_S = 1e9
    US_PER_NS = 1000
    TV_NSEC_MAX = (NS_PER_S - 1)

    # Assuming self responds to setting the value of [:tv_sec] and
    # [:tv_nsec], add +secs+ to the time spec.
    def add_seconds!(float_sec)
      # add timeout in seconds to abs_timeout; careful with rounding
      sec = float_sec.floor
      nsec = ((float_sec - sec) * NS_PER_S).floor

      self[:tv_sec] += sec
      self[:tv_nsec] += nsec
      while self[:tv_nsec] > TV_NSEC_MAX
        self[:tv_sec] += 1
        self[:tv_nsec] -= NS_PER_S
      end
    end
  end
end
