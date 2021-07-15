# frozen_string_literal: true

require_relative 'lib/telemetry/scriber/version'

Gem::Specification.new do |spec|
  spec.name          = 'telemetry-scriber'
  spec.version       = Telemetry::Scriber::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matt.iverson@optum.com']

  spec.summary       = 'Telemetry Scriber gem for telemetry data'
  spec.description   = 'A gem that grabs data from Telemetry::AMQP and sends it to an InfluxDB endpoint'
  spec.homepage      = 'https://github.com/Optum/telemetry-scriber'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Optum/telemetry-scriber'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/Optum/telemetry-scriber/issues'
  spec.metadata['changelog_uri'] = 'https://github.com/Optum/telemetry-scriber/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'concurrent-ruby-ext'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'faraday-request-timer'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'net-http-persistent'
  spec.add_dependency 'oj', '>= 3.11'

  spec.add_dependency 'telemetry-amqp'
  spec.add_dependency 'telemetry-logger'
  spec.add_dependency 'telemetry-metrics-parser'
  spec.add_dependency 'telemetry-pki'
end
