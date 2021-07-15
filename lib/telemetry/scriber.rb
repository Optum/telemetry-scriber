ENV['telemetry.scriber.writer.host'] = 'apsrp03939'
ENV['telemetry.scriber.writer.port'] = '8080'
ENV['telemetry.scriber.writer.use_ssl'] = 'true'

require 'telemetry/logger'
require 'telemetry/scriber/defaults'
require 'telemetry/scriber/lock_helper'
require 'telemetry/scriber/reader'
require 'telemetry/scriber/writer'

module Telemetry
  module Scriber
    @databases = []
    @start_time = Time.now
    @last_push = Time.now

    class << self
      include Scriber::Defaults
      include Scriber::LockHelper
      attr_accessor :databases

      def bootstrap
        Telemetry::Logger.setup(send_to_amqp: false)
        Telemetry::Logger.info "Starting Scriber v#{Telemetry::Scriber::VERSION}"
        Telemetry::Logger.info "Using InfluxDB SSL? #{Telemetry::Scriber::Writer.use_ssl?}"
        Telemetry::Logger.unknown Telemetry::Scriber::Writer.port
        Telemetry::Logger.error 'Issues connecting to InfluxDB' unless Telemetry::Scriber::Writer.healthy?
        Telemetry::Scriber::Reader.exchange

        Telemetry::Logger.info 'bootstrap complete'

        start_reader
      end

      def start_reader
        Telemetry::Scriber::Reader.start
        Telemetry::Scriber::Reader.subscribe!
      end

      def stop
        Telemetry::Logger.info 'Scriber is exiting'
        Telemetry::Scriber::Reader.subscription.cancel
        Telemetry::Logger.info "Flushing final #{Scriber::Reader.metrics_count.value} metrics.."
        Telemetry::Scriber.databases.each do |database|
          data = Telemetry::Scriber.payload(database)
          next if data.count.zero?

          Telemetry::Scriber::Writer.send_metrics(data.join("\n"), database)
        end
      end

      def conditional_flush
        flush if Telemetry::Scriber::Reader.metrics_count.value > 10_000 || @last_push + 10 < Time.now
      end

      def flush
        Telemetry::Scriber.databases.each do |database|
          @local_data = nil
          Telemetry::Scriber.database_lock(database).with_write_lock do
            @local_data = Scriber.payload(database)
            Telemetry::Scriber.reset_payload(database)
            Telemetry::Scriber::Reader.metrics_count.value = 0
          end

          line_count = @local_data.count
          next if @local_data.count.zero?

          results = Telemetry::Scriber::Writer.send_metrics(@local_data.join("\n"), database)

          if results.is_a?(Faraday::Response)
            Telemetry::Logger.info(
              "Wrote #{line_count} lines to #{database} in #{(results.env[:duration] * 1000).round}ms"
            )
          end
          Telemetry::Scriber::Reader.ack!
          @last_push = Time.now
        end
      end
    end
  end
end
