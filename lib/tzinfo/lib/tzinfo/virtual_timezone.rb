module TZInfo
  class VirtualTimezone < Timezone
    def self.new(seconds_from_gmt)
      vt = super()
      vt.send(:setup, seconds_from_gmt)
      vt
    end

    # Returns the TimezonePeriod based on the given seconds from GMT.
    def period_for_utc(_utc)
      TimezonePeriod.new(nil, nil, @offset)
    end

    # Returns the array of TimezonePeriod based on the given seconds from GMT.
    def periods_for_local(_local)
      [TimezonePeriod.new(nil, nil, @offset)]
    end

    def identifier
      "secondsFromGMT##{@seconds_from_gmt}"
    end

    private

      def setup(seconds_from_gmt)
        @seconds_from_gmt = seconds_from_gmt
        @offset = TimezoneOffset.new(@seconds_from_gmt, 0, :VirtualTimeZone)
      end
  end
end
