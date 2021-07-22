require 'telemetry/scriber/defaults'
require 'telemetry/amqp'

module Telemetry
  module Scriber
    module AMQPHelper
      extend Telemetry::Scriber::Defaults

      @global_tag_location = Concurrent::AtomicFixnum.new(0)
      def session
        @session ||= Telemetry::AMQP::Base.new(
          auto_start: true,
          vhost: vhost,
          application: application,
          app_version: app_version,
          port: port
        )
      end

      def channel
        if !@channel_thread.nil? && !@channel_thread.value.nil? && @channel_thread.value.open?
          return @channel_thread.value
        end

        @channel_thread = Concurrent::ThreadLocalVar.new(nil) if @channel_thread.nil?
        @channel_thread.value = session.create_channel
        @channel_thread.value
      end

      def vhost
        if opts.key? :vhost
          opts[:vhost]
        elsif ENV.key? "#{env_key}.consumer.vhost"
          ENV["#{env_key}.consumer.vhost"]
        else
          'telemetry'
        end
      end

      def port
        if opts.key? :vhost
          opts[:port]
        elsif ENV.key? "#{env_key}.consumer.port"
          ENV["#{env_key}.consumer.port"].to_i
        else
          5672
        end
      end

      def application
        'scriber'
      end

      def app_version
        Scriber::VERSION
      end

      def consumer_tag
        "scriber_v#{Scriber::VERSION}.#{hostname}.#{Thread.current.object_id}"
      end

      def global_tag_location
        @global_tag_location.value
      end

      def global_tag_location=(number)
        @global_tag_location.value = number
      end

      def ack!
        channel.acknowledge(global_tag_location, true)
      end

      def reset_queue!
        queue.delete(if_unused: true, if_empty: true)
        @queue = nil
        queue
      end
    end
  end
end
