require 'tzinfo/virtual_timezone'
require 'active_support/values/time_zone'

ActiveSupport::TimeZone.class_eval do
  class << self
    alias_method :square_brackets, :[]
    def [](arg)
      case arg
      when Numeric, ActiveSupport::Duration
        tzinfo = TZInfo::VirtualTimezone.new(arg)
        @lazy_zones_map[arg] ||= create(tzinfo.name, nil, tzinfo)
      else
        square_brackets(arg)
      end
    end
  end
end
