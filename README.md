# VirtualTimeZoneRails

Updates the original behaviour of ActiveSupport::TimeZone
to ignore daylight savings and keep consistent offset
when initialized with Numeric or ActiveSupport::Duration.

(Similar behaviour to the [Swift3 TimeZone](https://developer.apple.com/documentation/foundation/timezone/2293718-init#discussion))

```ruby
zone = ActiveSupport::TimeZone.new(-28800)
time = zone.parse('2017-08-01') # => Tue, 01 Aug 2017 00:00:00 VirtualTimeZone -08:00
time.utc_offset # => -28800
```

The original behaviour was like this.
```ruby
zone = ActiveSupport::TimeZone.new(-28800)
time = zone.parse('2017-08-01') # => Tue, 01 Aug 2017 00:00:00 PDT -07:00
time.utc_offset # => -25200, not -28800
```

This gem does not change the behaviour if the _real_ time zone is given.

```ruby
zone = ActiveSupport::TimeZone.new("America/New_York")
zone.parse('2017-08-01') # => Tue, 01 Aug 2017 00:00:00 EDT -04:00
time.utc_offset # => -14400
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'virtual_time_zone_rails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install virtual_time_zone_rails

## Usage

Just include to the Gemfile of your rails project.

### NOTE!!
This gem does not implicitly convert numeric hours to milliseconds like original ActiveSupport::TimeZone does.
(ActiveRecord::TimeZone implicitly convert numeric from -13 to 13 to milliseconds by multiplying with 3600)

If your code relies on this feature, please update by one of the following ways.

Original code:
```ruby
ActiveSupport::TimeZone.new(9)
```
Updated code:
```ruby
ActiveSupport::TimeZone.new(9.hours)
```
or
```ruby
ActiveSupport::TimeZone.new(9 * 3600)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nobuhikosawai/virtual_time_zone_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
