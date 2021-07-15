require 'concurrent'

module Telemetry
  module Scriber
    module LockHelper
      @databases = []
      def database_lock(database)
        database = "@#{database}".to_sym
        return instance_variable_get(database) if instance_variable_defined?(database)

        instance_variable_set(database, Concurrent::ReentrantReadWriteLock.new)
      end

      def reset_payload(database)
        database = "@#{database}_payload".to_sym
        instance_variable_set(database, Concurrent::Array.new)
      end

      def metric_count(database)
        database = "@#{database}_count".to_sym
        return instance_variable_get(database) if instance_variable_defined?(database)

        instance_variable_set(database, 0)
      end

      def payload(database)
        database_orig = database
        database = "@#{database}_payload".to_sym
        return instance_variable_get(database) if instance_variable_defined?(database)

        @databases.push(database_orig)
        instance_variable_set(database, Concurrent::Array.new)
      end
    end
  end
end
