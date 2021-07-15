require 'telemetry/scriber/writer_defaults'
require 'faraday'
require 'faraday_middleware'
require 'faraday-request-timer'

module Telemetry
  module Scriber
    module Writer
      extend Telemetry::Scriber::Writer::Defaults
      class << self
        def healthy?
          connection.get('/health').success?
        end

        def connection
          @connection = Faraday.new(
            "#{use_ssl? ? 'https' : 'http'}://#{host}:#{port}",
            { ssl: use_ssl? ? ssl_options : {} }
          ) do |connection|
            connection.response :json, content_type: /\bjson$/
            connection.request :retry, retry_options if retry?
            connection.request :timer
            connection.adapter :net_http_persistent, pool_size: pool_size do |http|
              http.idle_timeout = idle_timeout
            end
          end
        end

        def use_ssl?
          @use_ssl unless @use_ssl.nil?

          return @use_ssl = true if ENV["#{env_key}.writer.use_ssl"] == '1'
          return @use_ssl = true if ENV["#{env_key}.writer.use_ssl"] == 'true'
          return @use_ssl = true if opts[:use_ssl]

          [port, 8443, 443, 8080, 8086].each do |port_test|
            next unless Faraday.new("https://#{host}:#{port_test}", { ssl: ssl_options }) do |connection|
              connection.options.timeout = 2
            end.get('/ping').success?

            @port = port_test
            @use_ssl = true
            return true
          rescue StandardError
            next
          end
          @use_ssl = false
        rescue StandardError => e
          Telemetry::Logger.error "error with use_ssl? #{e.class} #{e.message}"
          @use_ssl = false
          false
        end

        def send_metrics(payload, database = 'telegraf')
          results = connection.post("/write?db=#{database}", payload) do |req|
            req.options.timeout = write_timeout + open_timeout
            req.options.open_timeout = open_timeout
            req.options.write_timeout = write_timeout
          end

          return results if results.success?

          Telemetry::Logger.warn "Failed to write to database #{database} with status #{results.status}"
          Telemetry::Logger.warn results.body

          queue_bad_metrics(payload, database)
        end

        def queue_bad_metrics(payload, database = 'telegraf')
          puts database
          puts payload
          false
        end
      end
    end
  end
end
