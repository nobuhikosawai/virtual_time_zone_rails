
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "virtual_time_zone_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "virtual_time_zone_rails"
  spec.version       = VirtualTimeZoneRails::VERSION
  spec.authors       = ["Nobuiko Sawai"]
  spec.email         = ["nobuhiko.sawai@gmail.com"]

  spec.summary       = %q{Virtual TimeZone}
  spec.description   = %q{Virtual TimeZone}
  spec.homepage      = "http://github.com/nobuhikosawai/virtual_time_zone_rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.0"
  spec.add_dependency "tzinfo", ">= 2.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "minitest", "~>5.1"
end
