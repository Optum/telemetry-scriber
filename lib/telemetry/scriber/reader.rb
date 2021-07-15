require 'telemetry/scriber/queue_defaults'
require 'telemetry/scriber/compress'
require 'telemetry/amqp'
require 'telemetry/metrics/parser'

module Telemetry
  module Scriber
    module Reader
      extend Telemetry::Scriber::Compress
      extend Telemetry::Scriber::QueueDefaults

      @tag_location = 0
      class << self
        attr_accessor :subscription, :tag_location

        def start
          # bind_node_groups
          # remove_stale_bindings!
          Telemetry::Logger.info 'Scriber::Reader setup complete'
        end

        def channel
          @channel ||= amqp.channel
        end

        def amqp
          @amqp ||= Telemetry::AMQP::Base.new(
            auto_start: true,
            vhost: 'telemetry',
            application: 'scriber',
            app_version: Scriber::VERSION,
            nodes: ['localhost'],
            port: 5672
          )
        end

        def node_groups
          return @node_groups unless @node_groups.nil?

          @node_groups = []
          Conflux::Client.groups(queue_name.split('.').last).each do |group|
            next unless group[:active] || group[:writable]

            @node_groups.push group[:name]
          end
        rescue StandardError
          []
        end

        def exchange
          @exchange ||= channel.topic(exchange_name, durable: true, auto_delete: false, internal: true,
                                                     'alternate-exchange': 'influxdb.overflow')
        rescue Bunny::PreconditionFailed
          @exchange ||= channel.topic(exchange_name, passive: true)
        end

        def exchange_name
          'influxdb.out'
        end

        def queue(name = queue_name)
          @queue ||= channel.queue(name, durable: true, arguments: queue_defaults)
        rescue Bunny::PreconditionFailed => e
          Telemetry::Logger.error e.message
          Telemetry::Logger.error e.backtrace[0..5]
          @queue = channel.queue(name, passive: true)
          reset_queue! if @queue.message_count.zero?
        end

        def reset_queue!
          queue.delete(if_unused: true, if_empty: true)
          @queue = nil
          queue
        end

        def consumer_tag
          "scriber_v#{Scriber::VERSION}.#{hostname}.#{Thread.current.object_id}"
        end

        def push
          Scriber.databases.each do |database|
            data = nil
            Scriber.database_lock(database).with_write_lock do
              data = Scriber.payload(database)
              Scriber.reset_payload(database)
            end
            next if data.nil? || data.count.zero?

            Scriber::Writer.send_metrics(data.join, database)
          end

          channel.acknowledge(@tag_location, true)
          metrics_count.value = 0
          @last_push = Time.now
        end

        def metrics_count
          @metrics_count ||= Concurrent::AtomicFixnum.new
        end

        def ack!
          channel.acknowledge(@tag_location, true)
        end

        def subscribe!
          @last_push = Time.now
          @start_time = Time.now

          @subscription = queue.subscribe(manual_ack: true, consumer_tag: consumer_tag) do |del, meta, payload|
            until metrics_count.value < 200_000
              Telemetry::Logger.warn "Metric buffer size is currently at #{metrics_count.value}, cooling down"
              sleep(0.25)
            end
            payload = deflate(payload) if meta[:content_encoding] == 'gzip'
            payload.lines.each { |line| line_parser(line.strip) }
            @tag_location = del.delivery_tag if del.delivery_tag > @tag_location
          end

          Telemetry::Logger.info "Scriber::Reader started subscription to queue #{queue_name}"
        end

        def line_parser(line)
          return if line.nil? || line.empty?

          results = Telemetry::Metrics::Parser.from_line_protocol(line)
          metrics_count.increment(results[:fields].count)
          database = if results[:tags].key? :influxdb_database
                       results[:tags][:influxdb_database]
                     elsif default_to_measurement_name
                       results[:measurement]
                     end

          Telemetry::Scriber.database_lock(database).with_read_lock do
            Telemetry::Scriber.payload(database).push line
          end
        end

        def default_to_measurement_name
          @default_to_measurement_name ||= if opts.key? :default_to_measurement_name
                                             opts[:default_to_measurement_name]
                                           elsif ENV.key? "#{env_key}.default_to_measurement_name"
                                             %w[1 true].include? ENV "#{env_key}.default_to_measurement_name"
                                           else
                                             true
                                           end
        end
      end
    end
  end
end
