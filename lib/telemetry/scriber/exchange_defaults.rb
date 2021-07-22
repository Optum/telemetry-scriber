module Telemetry
  module Scriber
    module ExchangeDefaults
      def exchange_name
        'telemetry.default'
      end

      def ex_alt_exchange
        'telemetry.alt_ex'
      end

      def ex_durable
        true
      end

      def ex_internal
        false
      end

      def auto_delete
        false
      end

      def ex_passive
        false
      end

      def routing_key
        'metric'
      end

      def ex_message_persistent
        true
      end

      def ex_message_mandatory
        false
      end
    end
  end
end
