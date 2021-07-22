require 'concurrent'

module Telemetry
  module Scriber
    module LockHelper
      @databases = Concurrent::Array.new

      def databases
        @databases
      end

      def database_lock(database)
        database = "@#{database}".to_sym
        return instance_variable_get(database) if instance_variable_defined?(database)

        instance_variable_set(database, Concurrent::ReentrantReadWriteLock.new)
      end

      def reset_payload(database)
        database = "@#{database}_payload".to_sym
        instance_variable_set(database, Concurrent::Array.new)
      end

      def payload(database)
        database_orig = database
        database = "@#{database}_payload".to_sym
        return instance_variable_get(database) if instance_variable_defined?(database)

        @databases.push(database_orig)
        instance_variable_set(database, Concurrent::Array.new)
      end

      def metric_count(database)
        database = "@#{database}_count".to_sym
        return instance_variable_get(database).value if instance_variable_defined?(database)

        instance_variable_set(database, Concurrent::AtomicFixnum.new)
        instance_variable_get(database).value
      end

      def metric_count_reset(database)
        database = "@#{database}_count".to_sym
        instance_variable_set(database, Concurrent::AtomicFixnum.new)
      end

      def metric_count_increment(database, count = 0)
        database = "@#{database}_count".to_sym
        instance_variable_get(database).increment(count)
      end

      def global_metric_count(count = 1)
        instance_variable_get(:@global_metric_count).increment(count)
      end

      def db_tag_location(database)
        database = "@#{database}_location".to_sym
        instance_variable_set(database, Concurrent::AtomicFixnum.new) unless instance_variable_defined?(database)

        instance_variable_set(database, Concurrent::Hash.new)
        0
      end

      def tag_location_set(database, location = tag_location)
        database = database.to_sym
        instance_variable_get(:tag_locations)[database] = location
      end
    end
  end
end
