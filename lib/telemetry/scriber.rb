ENV['telemetry.scriber.writer.host'] = 'apsrp03939'
ENV['telemetry.scriber.writer.port'] = '8080'
ENV['telemetry.scriber.writer.use_ssl'] = 'true'

require 'telemetry/logger'

require 'telemetry/scriber/defaults'
# require 'telemetry/scriber/lock_helper'
require 'telemetry/scriber/buffer'
require 'telemetry/scriber/consumer'
require 'telemetry/scriber/writer'
require 'telemetry/scriber/publisher'

module Telemetry
  module Scriber
    @databases = []
    @start_time = Time.now
    @last_push = Time.now
    @tag_location = 0
    @high_tag = 0

    class << self
      include Scriber::Defaults
      def bootstrap
        Telemetry::Logger.setup(color: true, colorize: true, level: 'info')
        Telemetry::Logger.log_level = 'info'
        Telemetry::Logger.info "Starting Scriber v#{Telemetry::Scriber::VERSION}"
        Telemetry::Logger.info "Using InfluxDB SSL? #{Telemetry::Scriber::Writer.use_ssl?}"
        if Telemetry::Scriber::Writer.healthy?
          Telemetry::Logger.info 'Connected to InfluxDB'
        else
          Telemetry::Logger.error 'Issues connecting to InfluxDB!'
        end
      end

      def start_reader
        Telemetry::Scriber::Consumer.subscribe!
      end

      def flush
        Telemetry::Scriber::Buffer.databases.each do |database|
          if @last_push.to_i <= Time.now.to_i - 100
            Telemetry::Logger.info 'its been more than 10 seconds since a flush, pusing now'
          elsif Telemetry::Scriber::Buffer.metric_count(database) < 2_000
            Telemetry::Logger.debug("skipping #{database} flusb because count is at #{Telemetry::Scriber::Buffer.metric_count(database)}") # rubocop:disable Layout/LineLength
            next
          end

          results = Telemetry::Scriber::Buffer.payload_grab_and_reset(database)
          @temp_tag = results[:tag_location]
          @tag_location = results[:tag_location] if results[:tag_location] > @tag_location
          @local_data = results[:data]

          line_count = @local_data.count
          if @local_data.count.zero?
            @last_push = Time.now
            next
          end

          write_results = Telemetry::Scriber::Writer.send_metrics(@local_data.join("\n"), database)
          if write_results.is_a?(Faraday::Response)
            Telemetry::Logger.info("Wrote #{line_count} lines, #{results[:metric_count]} metrics to #{database} in #{(write_results.env[:duration] * 1000).round}ms") # rubocop:disable Layout/LineLength
          else
            Telemetry::Logger.fatal "#{write_results.class}: #{write_results}"
          end

          @last_push = Time.now
        end

        if @tag_location.positive? && @tag_location > @high_tag
          Telemetry::Logger.debug 'it was positive and is going to ack'
          @high_tag = @temp_tag
          Telemetry::Scriber::Consumer.ack(@temp_tag)
          true
        else
          Telemetry::Logger.debug 'it was negatve and is not going to ack'
          false
        end
      end

      def stop
        @stopping_at = Time.now.to_i
        Telemetry::Logger.info 'Scriber is exiting'
        Telemetry::Scriber::Consumer.cancel!
        Telemetry::Logger.info 'Flushing final metrics..'
        until !flush || @stopping_at + 10 < Time.now.to_i
        end
      end
    end
  end
end
