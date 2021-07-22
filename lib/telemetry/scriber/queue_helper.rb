module Telemetry
  module Scriber
    module QueueHelper
      def remove_stale_bindings!
        amqp.ex_q_bindings(exchange: exchange_name, queue: queue_name).each do |binding|
          next if node_groups.include? binding[:properties_key]

          Telemetry::Logger.warn "Removing binding for #{exchange_name} -> #{binding[:properties_key]} -> #{queue_name}"
          amqp.remove_binding(key: binding[:properties_key], queue: queue_name)
        end
      rescue StandardError => e
        Telemetry::Logger.warn "remove_stale_bindings! #{e.class}:#{e.message}"
        Telemetry::Logger.warn e.backtrace[0..10]
      end

      def bind_node_groups
        node_groups.each do |node_group|
          queue.bind(exchange, routing_key: node_group[:name])
          Telemetry::Logger.info "Adding binding for #{exchange_name} -> #{node_group[:name]} -> #{queue_name}"
        rescue StandardError => e
          Telemetry::Logger.error "Failed to bind, message: #{e.message}, node_group: #{node_group[:name]}"
          Telemetry::Logger.error e.backtrace[0..5]
        end
      rescue StandardError => e
        Telemetry::Logger.error "Failed to create bindings with message: #{e.message}"
        Telemetry::Logger.error e.backtrace[0..5]
      end
    end
  end
end
