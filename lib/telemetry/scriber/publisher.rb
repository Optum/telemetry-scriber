require 'telemetry/scriber/exchange_defaults'
require 'telemetry/scriber/amqp_helper'

module Telemetry
  module Scriber
    module Publisher
      extend Telemetry::Scriber::ExchangeDefaults
      extend Telemetry::Scriber::AMQPHelper

      class << self
        def publish_error(results, payload, database)
          payload[:results] = {
            status: results.status
          }
          payload[:database] = database
          payload = MultiJson.dump(payload) unless payload.is_a? String
          error_exchange.publish(payload, **publish_opts, routing_key: 'publish_error')
        end

        def publish_line(line, routing_key:, **)
          line_exchange.publish(line, **publish_opts, routing_key: routing_key)
        end

        def error_exchange
          @exchange ||= channel.topic(
            'telemetry.metric_errors',
            durable: true,
            auto_delete: auto_delete,
            internal: internal,
            'alternate-exchange': ex_alt_exchange,
            passive: ex_passive
          )
        rescue Bunny::PreconditionFailed
          @exchange ||= channel.topic('telemetry.metric_errors', passive: true)
        end

        def line_exchange
          @exchange ||= channel.topic(
            exchange_name,
            durable: true,
            auto_delete: auto_delete,
            internal: internal,
            'alternate-exchange': ex_alt_exchange,
            passive: ex_passive
          )
        rescue Bunny::PreconditionFailed
          @exchange ||= channel.topic(exchange_name, passive: true)
        end

        def publish_opts
          {
            routing_key: routing_key,
            persistent: ex_message_persistent,
            mandatory: ex_message_mandatory,
            timstamp: Time.now.to_i,
            type: 'metric',
            content_type: 'application/json',
            content_encoding: 'identity'
          }
        end
      end
    end
  end
end
