module Telemetry
  module Scriber
    module Defaults
      def hostname
        @hostname ||= Socket.gethostname.split('.').first
      end

      def opts
        @opts ||= {}
      end

      def env_key
        'telemetry.scriber'
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
