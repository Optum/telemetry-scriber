require 'telemetry/scriber/defaults'

module Telemetry
  module Scriber
    module QueueDefaults
      include Telemetry::Scriber::Defaults

      def opts
        @opts ||= { queue_defaults: {} }
      end

      def queue_name
        opts[:queue_name] || ENV["#{env_key}.queue_name"] || hostname.downcase
      end

      def x_queue_type
        opts[:queue_defaults][:queue_type] || ENV["#{env_key}.queue.queuetype"] || 'quorum'
      end

      def x_max_in_memory_bytes
        opts[:queue_defaults][:max_in_memory_bytes] || ENV["#{env_key}.queue.maxinmemorybytes"] || 104_857_600
      end

      def x_max_in_memory_length
        opts[:queue_defaults][:max_in_memory_length] || ENV["#{env_key}.queue.maxinmemorylength"] || 2000
      end

      def x_dead_letter_ex
        opts[:queue_defaults][:dead_letter_ex] || ENV["#{env_key}.queue.deadletterexchange"] || 'telemetry.overflow'
      end

      def x_overflow
        opts[:queue_defaults][:overflow] || ENV["#{env_key}.queue.x"] || 'drop-head'
      end

      def x_delivery_limit
        opts[:queue_defaults][:delivery_limit] || ENV["#{env_key}.queue.x"] || 2
      end

      def x_max_length_bytes
        opts[:queue_defaults][:max_length_bytes] || ENV["#{env_key}.queue.x"] || 1_073_741_824
      end

      def x_max_length
        opts[:queue_defaults][:max_length] || ENV["#{env_key}.queue.maxlength"] || 10_000
      end

      def x_expires
        opts[:queue_defaults][:expires] || ENV["#{env_key}.queue.expires"] || 60_000
      end

      def queue_defaults
        {
          # 'x-expires': x_expires,
          'x-max-length': x_max_length,
          'x-max-length-bytes': x_max_length_bytes,
          'x-delivery-limit': x_delivery_limit,
          'x-overflow': x_overflow,
          'x-dead-letter-exchange': x_dead_letter_ex,
          'x-max-in-memory-length': x_max_in_memory_length,
          'x-max-in-memory-bytes': x_max_in_memory_bytes,
          'x-queue-type': x_queue_type
        }
      end
    end
  end
end
