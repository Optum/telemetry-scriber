require 'telemetry/scriber/queue_defaults'
require 'telemetry/scriber/amqp_helper'
require 'telemetry/metrics/parser'
require 'telemetry/scriber/compress'
require 'telemetry/scriber/lock_helper'
require 'digest'

module Telemetry
  module Scriber
    module Consumer
      extend Telemetry::Scriber::Compress
      extend Telemetry::Scriber::QueueDefaults
      extend Telemetry::Scriber::LockHelper
      extend Telemetry::Scriber::AMQPHelper

      @databases = Concurrent::Array.new
      class << self
        def queue(name = "#{queue_prefix}#{queue_name}")
          return @queue if @queue.is_a?(Bunny::Queue) && @queue.channel.connection != :closed

          # channel.basic_qos(1, false)
          @queue = channel.queue(name, durable: queue_durable, arguments: queue_defaults)
        rescue Bunny::PreconditionFailed => e
          Telemetry::Logger.error "#{e.class}: #{e.message}"
          Telemetry::Logger.warn "Attempting to connect to the queue #{name} with passive: true"

          @queue = channel.queue(name, passive: true)
          return @queue if @queue.message_count.positive?

          Telemetry::Logger.warn "resetting queue(#{name}) since it is empty and not configured correctly"
          reset_queue!
        end

        def exchange
          @exchange ||= channel.topic(
            exchange_name,
            durable: durable,
            auto_delete: auto_delete,
            internal: internal,
            'alternate-exchange': ex_alt_exchange,
            passive: ex_passive
          )
        rescue Bunny::PreconditionFailed
          @exchange ||= channel.topic(exchange_name, passive: true)
        end

        def subscribe!
          @last_push = Time.now
          @start_time = Time.now

          queue.channel.basic_qos(25, false)
          @subscription = queue.subscribe(manual_ack: true, consumer_tag: consumer_tag) do |del, meta, payload|
            payload = decompress(payload) if meta[:content_encoding] == 'gzip'

            payload.lines.each do |line|
              line = line.strip!
              next if line.size < 4

              database = line_parser(line)
              @databases.push database unless @databases.include? database
            rescue StandardError => e
              Telemetry::Logger.error "#{e.class}: #{e.message}, #{line}"
              Telemetry::Logger.debug e.backtrace[0..2]
            end

            @databases.each do |database|
              Telemetry::Scriber::Buffer.db_tag_location_update(del.delivery_tag, 'scriber', database)
            end
          end

          Telemetry::Logger.info "Consumer started subscription to queue #{queue_name}"
        end

        def line_parser(line)
          if line.nil?
            Telemetry::Logger.warn 'line is nil' if line.nil?
            Telemetry::Logger.warn line

            return nil
          end

          r = Ractor.new line do |msg|
            Ractor.yield Telemetry::Metrics::Parser.from_line_protocol(msg)
          end
          results = r.take
          # results = Telemetry::Metrics::Parser.from_line_protocol(line)
          database = if results[:tags].key? :influxdb_database
                       results[:tags][:influxdb_database]
                     elsif default_to_measurement_name
                       results[:measurement]
                     end

          database_lock(database).with_read_lock do
            Telemetry::Scriber::Buffer.payload_push(database, line)
            Telemetry::Scriber::Buffer.metric_count_increment(database, results[:fields].count)
          end

          database
        rescue StandardError => e
          Telemetry::Logger.error "#{e.class}: #{e.message}, #{line}"
          Telemetry::Logger.error e.backtrace
        end

        def ack(location = @tag_location)
          Telemetry::Logger.debug "calling ack(#{location})"
          queue.channel.ack(location, true)
        end

        def cancel!
          @subscription.cancel
        end
      end
    end
  end
end
