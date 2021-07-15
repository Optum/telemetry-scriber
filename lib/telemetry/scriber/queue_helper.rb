module Telemetry
  module Scriber
    module QueueHelper
      def remove_stale_bindings!
        amqp.ex_q_bindings(exchange: exchange_name, queue: queue_name).each do |binding|
          next if node_groups.include? binding[:properties_key]

          Optum::Logger.warn "Removing binding for #{exchange_name} -> #{binding[:properties_key]} -> #{queue_name}"
          amqp.remove_binding(key: binding[:properties_key], queue: queue_name)
        end
      rescue StandardError => e
        Optum::Logger.warn "remove_stale_bindings! #{e.class}:#{e.message}"
        Optum::Logger.warn e.backtrace[0..10]
      end

      def bind_node_groups
        node_groups.each do |node_group|
          queue.bind(exchange, routing_key: node_group[:name])
          Optum::Logger.info "Adding binding for #{exchange_name} -> #{node_group[:name]} -> #{queue_name}"
        rescue StandardError => e
          Optum::Logger.error "Failed to bind, message: #{e.message}, node_group: #{node_group[:name]}"
          Optum::Logger.error e.backtrace[0..5]
        end
      rescue StandardError => e
        Optum::Logger.error "Failed to create bindings with message: #{e.message}"
        Optum::Logger.error e.backtrace[0..5]
      end
    end
  end
end
