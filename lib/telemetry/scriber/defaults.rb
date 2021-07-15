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
    end
  end
end
