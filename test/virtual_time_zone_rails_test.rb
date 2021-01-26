require 'test_helper'

class VirtualTimeZoneRailsTest < ActiveSupport::TestCase
  include TimeZoneTestHelpers
  def test_utc_to_local
    zone = ActiveSupport::TimeZone[-18000]
    assert_equal Time.utc(1999, 12, 31, 19), zone.utc_to_local(Time.utc(2000, 1)) # standard offset -0500
    assert_equal Time.utc(2000, 6, 30, 19), zone.utc_to_local(Time.utc(2000, 7)) # standard offset -0500
  end

  def test_local_to_utc
    zone = ActiveSupport::TimeZone[-18000]
    assert_equal Time.utc(2000, 1, 1, 5), zone.local_to_utc(Time.utc(2000, 1)) # standard offset -0500
    assert_equal Time.utc(2000, 7, 1, 5), zone.local_to_utc(Time.utc(2000, 7)) # standard offset -0500
  end

  def test_period_for_local
    zone = ActiveSupport::TimeZone[-18000]
    assert_instance_of TZInfo::OffsetTimezonePeriod, zone.period_for_local(Time.utc(2000))
  end

  def test_now
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000].dup
      def zone.time_now; Time.local(2000); end
      assert_instance_of ActiveSupport::TimeWithZone, zone.now
      assert_equal Time.utc(2000, 1, 1, 5), zone.now.utc
      assert_equal Time.utc(2000), zone.now.time
      assert_equal zone, zone.now.time_zone
    end
  end

  def test_now_not_enforces_spring_dst_rules
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000].dup
      def zone.time_now
        Time.local(2006, 4, 2, 2) # 2AM springs forward to 3AM if spring dst rule applies.
      end

      assert_equal Time.utc(2006, 4, 2, 2), zone.now.time
      assert_equal false, zone.now.dst?
    end
  end

  def test_now_not_enforces_fall_dst_rules
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000].dup
      def zone.time_now
        Time.at(1162098000) # equivalent to 1AM DST if fall dst applies.
      end
      assert_equal Time.utc(2006, 10, 29, 0), zone.now.time
      assert_equal false, zone.now.dst?
    end
  end

  def test_today
    travel_to(Time.utc(2000, 1, 1, 4, 59, 59)) # 1 sec before midnight Jan 1 EST
    assert_equal Date.new(1999, 12, 31), ActiveSupport::TimeZone[-18000].today
    travel_to(Time.utc(2000, 1, 1, 5)) # midnight Jan 1 EST
    assert_equal Date.new(2000, 1, 1), ActiveSupport::TimeZone[-18000].today
    travel_to(Time.utc(2000, 1, 2, 4, 59, 59)) # 1 sec before midnight Jan 2 EST
    assert_equal Date.new(2000, 1, 1), ActiveSupport::TimeZone[-18000].today
    travel_to(Time.utc(2000, 1, 2, 5)) # midnight Jan 2 EST
    assert_equal Date.new(2000, 1, 2), ActiveSupport::TimeZone[-18000].today
    travel_back
  end

  def test_tomorrow
    travel_to(Time.utc(2000, 1, 1, 4, 59, 59)) # 1 sec before midnight Jan 1 EST
    assert_equal Date.new(2000, 1, 1), ActiveSupport::TimeZone[-18000].tomorrow
    travel_to(Time.utc(2000, 1, 1, 5)) # midnight Jan 1 EST
    assert_equal Date.new(2000, 1, 2), ActiveSupport::TimeZone[-18000].tomorrow
    travel_to(Time.utc(2000, 1, 2, 4, 59, 59)) # 1 sec before midnight Jan 2 EST
    assert_equal Date.new(2000, 1, 2), ActiveSupport::TimeZone[-18000].tomorrow
    travel_to(Time.utc(2000, 1, 2, 5)) # midnight Jan 2 EST
    assert_equal Date.new(2000, 1, 3), ActiveSupport::TimeZone[-18000].tomorrow
  end

  def test_yesterday
    travel_to(Time.utc(2000, 1, 1, 4, 59, 59)) # 1 sec before midnight Jan 1 EST
    assert_equal Date.new(1999, 12, 30), ActiveSupport::TimeZone[-18000].yesterday
    travel_to(Time.utc(2000, 1, 1, 5)) # midnight Jan 1 EST
    assert_equal Date.new(1999, 12, 31), ActiveSupport::TimeZone[-18000].yesterday
    travel_to(Time.utc(2000, 1, 2, 4, 59, 59)) # 1 sec before midnight Jan 2 EST
    assert_equal Date.new(1999, 12, 31), ActiveSupport::TimeZone[-18000].yesterday
    travel_to(Time.utc(2000, 1, 2, 5)) # midnight Jan 2 EST
    assert_equal Date.new(2000, 1, 1), ActiveSupport::TimeZone[-18000].yesterday
  end

  def test_travel_to_a_date
    with_env_tz do
      Time.use_zone(-36000) do
        date = Date.new(2014, 2, 18)
        time = date.midnight

        travel_to date do
          assert_equal date, Date.current
          assert_equal time, Time.current
        end
      end
    end
  end

  def test_local
    time = ActiveSupport::TimeZone[-36000].local(2007, 2, 5, 15, 30, 45)
    assert_equal Time.utc(2007, 2, 5, 15, 30, 45), time.time
    assert_equal ActiveSupport::TimeZone[-36000], time.time_zone
  end

  def test_local_not_enforces_spring_dst_rules
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.local(2006, 4, 2, 1, 59, 59) # 1 second before DST start in America/New_York
    assert_equal Time.utc(2006, 4, 2, 1, 59, 59), twz.time
    assert_equal Time.utc(2006, 4, 2, 6, 59, 59), twz.utc
    assert_equal false, twz.dst?
    assert_equal "VirtualTimeZone", twz.zone
    twz2 = zone.local(2006, 4, 2, 2) # If DST is applied, 2AM is now forwarded to 3AM
    assert_equal Time.utc(2006, 4, 2, 2), twz2.time # twz is created for 3AM
    assert_equal Time.utc(2006, 4, 2, 7), twz2.utc
    assert_equal false, twz2.dst?
    assert_equal "VirtualTimeZone", twz2.zone
    twz3 = zone.local(2006, 4, 2, 2, 30)
    assert_equal Time.utc(2006, 4, 2, 2, 30), twz3.time
    assert_equal Time.utc(2006, 4, 2, 7, 30), twz3.utc
    assert_equal false, twz3.dst?
    assert_equal "VirtualTimeZone", twz3.zone
  end

  def test_local_not_enforces_fall_dst_rules
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.local(2006, 10, 29, 1) # During fall DST if DST rule is applied.
    assert_equal Time.utc(2006, 10, 29, 1), twz.time
    assert_equal Time.utc(2006, 10, 29, 6), twz.utc
    assert_equal false, twz.dst?
    assert_equal "VirtualTimeZone", twz.zone
  end

  def test_at
    zone = ActiveSupport::TimeZone[-18000]
    secs = 946684800.0
    twz = zone.at(secs)
    assert_equal Time.utc(1999, 12, 31, 19), twz.time
    assert_equal Time.utc(2000), twz.utc
    assert_equal zone, twz.time_zone
    assert_equal secs, twz.to_f
  end

  def test_iso8601
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("1999-12-31T19:00:00")
    assert_equal Time.utc(1999, 12, 31, 19), twz.time
    assert_equal Time.utc(2000), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_iso8601_with_fractional_seconds
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("1999-12-31T19:00:00.750")
    assert_equal 750000, twz.time.usec
    assert_equal Time.utc(1999, 12, 31, 19, 0, 0 + Rational(3, 4)), twz.time
    assert_equal Time.utc(2000, 1, 1, 0, 0, 0 + Rational(3, 4)), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_iso8601_with_zone
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("1999-12-31T14:00:00-10:00")
    assert_equal Time.utc(1999, 12, 31, 19), twz.time
    assert_equal Time.utc(2000), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_iso8601_with_invalid_string
    zone = ActiveSupport::TimeZone[-18000]

    exception = assert_raises(ArgumentError) do
      zone.iso8601("foobar")
    end

    assert_equal "invalid date", exception.message
  end

  def test_iso8601_with_missing_time_components
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("1999-12-31")
    assert_equal Time.utc(1999, 12, 31, 0, 0, 0), twz.time
    assert_equal Time.utc(1999, 12, 31, 5, 0, 0), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_iso8601_with_old_date
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("1883-12-31T19:00:00")
    assert_equal [0, 0, 19, 31, 12, 1883], twz.to_a[0, 6]
    assert_equal zone, twz.time_zone
  end

  def test_iso8601_far_future_date_with_time_zone_offset_in_string
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("2050-12-31T19:00:00-10:00") # i.e., 2050-01-01 05:00:00 UTC
    assert_equal [0, 0, 0, 1, 1, 2051], twz.to_a[0, 6]
    assert_equal zone, twz.time_zone
  end

  def test_iso8601_should_not_black_out_system_timezone_dst_jump
    with_env_tz("EET") do
      zone = ActiveSupport::TimeZone[-28800]
      twz = zone.iso8601("2012-03-25T03:29:00")
      assert_equal [0, 29, 3, 25, 3, 2012], twz.to_a[0, 6]
    end
  end

  def test_iso8601_should_not_black_out_app_timezone_dst_jump
    with_env_tz("EET") do
      zone = ActiveSupport::TimeZone[-28800]
      twz = zone.iso8601("2012-03-11T02:29:00")
      assert_equal [0, 29, 2, 11, 3, 2012], twz.to_a[0, 6]
    end
  end

  def test_iso8601_doesnt_use_local_dst
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone["UTC"]
      twz = zone.iso8601("2013-03-10T02:00:00")
      assert_equal Time.utc(2013, 3, 10, 2, 0, 0), twz.time
    end
  end

  def test_iso8601_doesnt_handle_dst_jump
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      twz = zone.iso8601("2013-03-10T02:00:00")
      assert_equal Time.utc(2013, 3, 10, 2, 0, 0), twz.time
    end
  end

  def test_parse
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.parse("1999-12-31 19:00:00")
    assert_equal Time.utc(1999, 12, 31, 19), twz.time
    assert_equal Time.utc(2000), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_parse_with_old_date
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.parse("1883-12-31 19:00:00")
    assert_equal [0, 0, 19, 31, 12, 1883], twz.to_a[0, 6]
    assert_equal zone, twz.time_zone
  end

  def test_parse_far_future_date_with_time_zone_offset_in_string
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.parse("2050-12-31 19:00:00 -10:00") # i.e., 2050-01-01 05:00:00 UTC
    assert_equal [0, 0, 0, 1, 1, 2051], twz.to_a[0, 6]
    assert_equal zone, twz.time_zone
  end

  def test_parse_returns_nil_when_string_without_date_information_is_passed_in
    zone = ActiveSupport::TimeZone[-18000]
    assert_nil zone.parse("foobar")
    assert_nil zone.parse("   ")
  end

  def test_parse_with_incomplete_date
    zone = ActiveSupport::TimeZone[-18000]
    zone.stub(:now, zone.local(1999, 12, 31)) do
      twz = zone.parse("19:00:00")
      assert_equal Time.utc(1999, 12, 31, 19), twz.time
    end
  end

  def test_parse_with_day_omitted
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      assert_equal Time.local(2000, 2, 1), zone.parse("Feb", Time.local(2000, 1, 1))
      assert_equal Time.local(2005, 2, 1), zone.parse("Feb 2005", Time.local(2000, 1, 1))
      assert_equal Time.local(2005, 2, 2), zone.parse("2 Feb 2005", Time.local(2000, 1, 1))
    end
  end

  def test_parse_should_not_black_out_system_timezone_dst_jump
    with_env_tz("EET") do
      zone = ActiveSupport::TimeZone[-28800]
      twz = zone.parse("2012-03-25 03:29:00")
      assert_equal [0, 29, 3, 25, 3, 2012], twz.to_a[0, 6]
    end
  end

  def test_parse_should_black_out_app_timezone_dst_jump
    with_env_tz("EET") do
      zone = ActiveSupport::TimeZone[-28800]
      twz = zone.parse("2012-03-11 02:29:00")
      assert_equal [0, 29, 2, 11, 3, 2012], twz.to_a[0, 6]
    end
  end

  def test_parse_with_missing_time_components
    zone = ActiveSupport::TimeZone[-18000]
    zone.stub(:now, zone.local(1999, 12, 31, 12, 59, 59)) do
      twz = zone.parse("2012-12-01")
      assert_equal Time.utc(2012, 12, 1), twz.time
    end
  end

  def test_parse_with_javascript_date
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.parse("Mon May 28 2012 00:00:00 GMT-0700 (PDT)")
    assert_equal Time.utc(2012, 5, 28, 7, 0, 0), twz.utc
  end

  def test_parse_doesnt_use_local_dst
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone["UTC"]
      twz = zone.parse("2013-03-10 02:00:00")
      assert_equal Time.utc(2013, 3, 10, 2, 0, 0), twz.time
    end
  end

  def test_parse_not_handles_dst_jump
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      twz = zone.parse("2013-03-10 02:00:00")
      assert_equal Time.utc(2013, 3, 10, 2, 0, 0), twz.time
    end
  end

  def test_rfc3339
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.rfc3339("1999-12-31T14:00:00-10:00")
    assert_equal Time.utc(1999, 12, 31, 19), twz.time
    assert_equal Time.utc(2000), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_rfc3339_with_fractional_seconds
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.iso8601("1999-12-31T14:00:00.750-10:00")
    assert_equal 750000, twz.time.usec
    assert_equal Time.utc(1999, 12, 31, 19, 0, 0 + Rational(3, 4)), twz.time
    assert_equal Time.utc(2000, 1, 1, 0, 0, 0 + Rational(3, 4)), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_rfc3339_with_missing_time
    zone = ActiveSupport::TimeZone[-18000]

    exception = assert_raises(ArgumentError) do
      zone.rfc3339("1999-12-31")
    end

    assert_equal "invalid date", exception.message
  end

  def test_rfc3339_with_missing_offset
    zone = ActiveSupport::TimeZone[-18000]

    exception = assert_raises(ArgumentError) do
      zone.rfc3339("1999-12-31T19:00:00")
    end

    assert_equal "invalid date", exception.message
  end

  def test_rfc3339_with_invalid_string
    zone = ActiveSupport::TimeZone[-18000]

    exception = assert_raises(ArgumentError) do
      zone.rfc3339("foobar")
    end

    assert_equal "invalid date", exception.message
  end

  def test_rfc3339_with_old_date
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.rfc3339("1883-12-31T19:00:00-05:00")
    assert_equal [0, 0, 19, 31, 12, 1883], twz.to_a[0, 6]
    assert_equal zone, twz.time_zone
  end

  def test_rfc3339_far_future_date_with_time_zone_offset_in_string
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.rfc3339("2050-12-31T19:00:00-10:00") # i.e., 2050-01-01 05:00:00 UTC
    assert_equal [0, 0, 0, 1, 1, 2051], twz.to_a[0, 6]
    assert_equal zone, twz.time_zone
  end

  def test_rfc3339_should_not_black_out_system_timezone_dst_jump
    with_env_tz("EET") do
      zone = ActiveSupport::TimeZone[-28800] #Time gap is -0800
      twz = zone.rfc3339("2012-03-25T03:29:00-07:00")
      assert_equal [0, 29, 2, 25, 3, 2012], twz.to_a[0, 6]
    end
  end

  def test_rfc3339_should_not_black_out_app_timezone_dst_jump
    with_env_tz("EET") do
      zone = ActiveSupport::TimeZone[-28800]
      twz = zone.rfc3339("2012-03-11T02:29:00-08:00")
      assert_equal [0, 29, 2, 11, 3, 2012], twz.to_a[0, 6]
    end
  end

  def test_rfc3339_doesnt_use_local_dst
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone["UTC"]
      twz = zone.rfc3339("2013-03-10T02:00:00Z")
      assert_equal Time.utc(2013, 3, 10, 2, 0, 0), twz.time
    end
  end

  def test_rfc3339_doesnt_handle_dst_jump
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      twz = zone.iso8601("2013-03-10T02:00:00-05:00")
      assert_equal Time.utc(2013, 3, 10, 2, 0, 0), twz.time
    end
  end

  def test_strptime
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.strptime("1999-12-31 12:00:00", "%Y-%m-%d %H:%M:%S")
    assert_equal Time.utc(1999, 12, 31, 17), twz
    assert_equal Time.utc(1999, 12, 31, 12), twz.time
    assert_equal Time.utc(1999, 12, 31, 17), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_strptime_with_nondefault_time_zone
    with_tz_default ActiveSupport::TimeZone[-28800] do
      zone = ActiveSupport::TimeZone[-18000]
      twz = zone.strptime("1999-12-31 12:00:00", "%Y-%m-%d %H:%M:%S")
      assert_equal Time.utc(1999, 12, 31, 17), twz
      assert_equal Time.utc(1999, 12, 31, 12), twz.time
      assert_equal Time.utc(1999, 12, 31, 17), twz.utc
      assert_equal zone, twz.time_zone
    end
  end

  def test_strptime_with_explicit_time_zone_as_abbrev
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.strptime("1999-12-31 12:00:00 PST", "%Y-%m-%d %H:%M:%S %Z")
    assert_equal Time.utc(1999, 12, 31, 20), twz
    assert_equal Time.utc(1999, 12, 31, 15), twz.time
    assert_equal Time.utc(1999, 12, 31, 20), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_strptime_with_explicit_time_zone_as_h_offset
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.strptime("1999-12-31 12:00:00 -08", "%Y-%m-%d %H:%M:%S %:::z")
    assert_equal Time.utc(1999, 12, 31, 20), twz
    assert_equal Time.utc(1999, 12, 31, 15), twz.time
    assert_equal Time.utc(1999, 12, 31, 20), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_strptime_with_explicit_time_zone_as_hm_offset
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.strptime("1999-12-31 12:00:00 -08:00", "%Y-%m-%d %H:%M:%S %:z")
    assert_equal Time.utc(1999, 12, 31, 20), twz
    assert_equal Time.utc(1999, 12, 31, 15), twz.time
    assert_equal Time.utc(1999, 12, 31, 20), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_strptime_with_explicit_time_zone_as_hms_offset
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.strptime("1999-12-31 12:00:00 -08:00:00", "%Y-%m-%d %H:%M:%S %::z")
    assert_equal Time.utc(1999, 12, 31, 20), twz
    assert_equal Time.utc(1999, 12, 31, 15), twz.time
    assert_equal Time.utc(1999, 12, 31, 20), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_strptime_with_almost_explicit_time_zone
    zone = ActiveSupport::TimeZone[-18000]
    twz = zone.strptime("1999-12-31 12:00:00 %Z", "%Y-%m-%d %H:%M:%S %%Z")
    assert_equal Time.utc(1999, 12, 31, 17), twz
    assert_equal Time.utc(1999, 12, 31, 12), twz.time
    assert_equal Time.utc(1999, 12, 31, 17), twz.utc
    assert_equal zone, twz.time_zone
  end

  def test_strptime_with_day_omitted
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      assert_equal Time.local(2000, 2, 1), zone.strptime("Feb", "%b", Time.local(2000, 1, 1))
      assert_equal Time.local(2005, 2, 1), zone.strptime("Feb 2005", "%b %Y", Time.local(2000, 1, 1))
      assert_equal Time.local(2005, 2, 2), zone.strptime("2 Feb 2005", "%e %b %Y", Time.local(2000, 1, 1))
    end
  end

  def test_strptime_with_malformed_string
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      assert_raise(ArgumentError) { zone.strptime("1999-12-31", "%Y/%m/%d") }
    end
  end

  def test_strptime_with_timestamp_seconds
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      time_str = "1470272280"
      time = zone.strptime(time_str, "%s")
      assert_equal Time.at(1470272280), time
    end
  end

  def test_strptime_with_timestamp_milliseconds
    with_env_tz "US/Eastern" do
      zone = ActiveSupport::TimeZone[-18000]
      time_str = "1470272280000"
      time = zone.strptime(time_str, "%Q")
      assert_equal Time.at(1470272280), time
    end
  end

  def test_utc_offset_is_not_cached_when_current_period_gets_stale
    tz = ActiveSupport::TimeZone.create("Moscow")
    travel_to(Time.utc(2014, 10, 25, 21)) do # 1 hour before TZ change
      assert_equal 14400, tz.utc_offset, "utc_offset should be initialized according to current_period"
    end

    travel_to(Time.utc(2014, 10, 25, 22)) do # after TZ change
      assert_equal 10800, tz.utc_offset, "utc_offset should not be cached when current_period gets stale"
    end
  end

  def test_seconds_to_utc_offset_with_colon
    assert_equal "-06:00", ActiveSupport::TimeZone.seconds_to_utc_offset(-21_600)
    assert_equal "+00:00", ActiveSupport::TimeZone.seconds_to_utc_offset(0)
    assert_equal "+05:00", ActiveSupport::TimeZone.seconds_to_utc_offset(18_000)
  end

  def test_seconds_to_utc_offset_without_colon
    assert_equal "-0600", ActiveSupport::TimeZone.seconds_to_utc_offset(-21_600, false)
    assert_equal "+0000", ActiveSupport::TimeZone.seconds_to_utc_offset(0, false)
    assert_equal "+0500", ActiveSupport::TimeZone.seconds_to_utc_offset(18_000, false)
  end

  def test_seconds_to_utc_offset_with_negative_offset
    assert_equal "-01:00", ActiveSupport::TimeZone.seconds_to_utc_offset(-3_600)
    assert_equal "-00:59", ActiveSupport::TimeZone.seconds_to_utc_offset(-3_599)
    assert_equal "-05:30", ActiveSupport::TimeZone.seconds_to_utc_offset(-19_800)
  end

  def test_formatted_offset_positive
    zone = ActiveSupport::TimeZone["New Delhi"]
    assert_equal "+05:30", zone.formatted_offset
    assert_equal "+0530", zone.formatted_offset(false)
  end

  def test_formatted_offset_negative
    zone = ActiveSupport::TimeZone[-18000]
    assert_equal "-05:00", zone.formatted_offset
    assert_equal "-0500", zone.formatted_offset(false)
  end

  def test_z_format_strings
    zone = ActiveSupport::TimeZone["Tokyo"]
    twz = zone.now
    assert_equal "+0900",     twz.strftime("%z")
    assert_equal "+09:00",    twz.strftime("%:z")
    assert_equal "+09:00:00", twz.strftime("%::z")
  end

  def test_formatted_offset_zero
    zone = ActiveSupport::TimeZone["London"]
    assert_equal "+00:00", zone.formatted_offset
    assert_equal "UTC", zone.formatted_offset(true, "UTC")
  end

  def test_zone_compare
    zone1 = ActiveSupport::TimeZone["Central Time (US & Canada)"] # offset -0600
    zone2 = ActiveSupport::TimeZone[-18000] # offset -0500
    assert zone1 < zone2
    assert zone2 > zone1
    assert zone1 == zone1
  end

  def test_zone_match
    zone = ActiveSupport::TimeZone[-18000]
    assert zone =~ /GMT/
    assert zone !~ /Nonexistent_Place/
  end

  def test_to_s
    assert_equal "(GMT+05:30) New Delhi", ActiveSupport::TimeZone["New Delhi"].to_s
  end

  def test_index
    assert_nil ActiveSupport::TimeZone["bogus"]
    assert_instance_of ActiveSupport::TimeZone, ActiveSupport::TimeZone["Central Time (US & Canada)"]
    assert_instance_of ActiveSupport::TimeZone, ActiveSupport::TimeZone[8]
    assert_raise(ArgumentError) { ActiveSupport::TimeZone[false] }
  end

  def test_unknown_zone_raises_exception
    assert_raise TZInfo::InvalidTimezoneIdentifier do
      ActiveSupport::TimeZone.create("bogus")
    end
  end

  def test_new
    assert_equal ActiveSupport::TimeZone[-21600], ActiveSupport::TimeZone.new(-21600)
  end

  def test_to_yaml
    assert_equal("--- !ruby/object:ActiveSupport::TimeZone\nname: secondsFromGMT#-18000\n", ActiveSupport::TimeZone[-18000].to_yaml)
  end

  def test_yaml_load
    #not support yaml load
  end
end
