require 'concurrent'

module Telemetry
  module Scriber
    module Buffer
      @databases = Concurrent::Array.new
      @consumers = Concurrent::Array.new
      @global_metric_count = Concurrent::AtomicFixnum.new(0)

      class << self
        attr_reader :databases

        def database_lock(database)
          Telemetry::Logger.debug "calling database_lock(#{database})"
          database = "@#{database}".to_sym
          if instance_variable_get(database).is_a?(Concurrent::ReentrantReadWriteLock)
            return instance_variable_get(database)
          end

          instance_variable_set(database, Concurrent::ReentrantReadWriteLock.new)
        rescue StandardError => e
          Telemetry::Logger.warn "#{e.class}: #{e.message}"
          Telemetry::Logger.warn e.backtrace
          raise e
        end

        def payload(database)
          database_orig = database
          database = "@#{database}_payload".to_sym
          return instance_variable_get(database) if instance_variable_defined?(database)

          @databases.push(database_orig)
          instance_variable_set(database, Concurrent::Array.new)
        end

        def payload_push(database, line)
          key = "@#{database}_payload".to_sym
          instance_variable_set(key, Concurrent::Array.new) unless instance_variable_defined?(key)

          @databases.push database unless @databases.include? database

          instance_variable_get(key).push(line)
          true
        end

        def payload_reset(database)
          key = "@#{database}_payload".to_sym
          instance_variable_get(key).clear
        end

        def payload_grab_and_reset(database, consumer = 'default')
          key = "@#{database}_payload".to_sym
          results = { tag_location: nil, data: [] }
          Telemetry::Scriber::Buffer.database_lock(database).with_write_lock do
            results[:data] = instance_variable_get(key).shift(15_000)
            results[:tag_location] = db_tag_location(consumer, database)
            results[:metric_count] = metric_count(database)
            metric_count_reset(database)
          end

          Telemetry::Logger.debug(
            "payload_grab_and_reset(#{database}) returned #{results[:data].class} with #{results[:data].count}"
          )
          results
        end

        def metric_count(database = 'telegraf')
          key = "@#{database}_count".to_sym
          if instance_variable_defined?(key)
            count = 0
            database_lock(database).with_read_lock do
              count = instance_variable_get(key).value
            end
            return count
          else
            instance_variable_set(key, Concurrent::AtomicFixnum.new)
          end

          0
        end

        def metric_count_reset(database = 'telegraf')
          key = "@#{database}_count".to_sym
          if instance_variable_defined?(key)
            instance_variable_get(key).value = 0
            return 0
          end
          instance_variable_set(key, Concurrent::AtomicFixnum.new) unless instance_variable_defined?(key)

          0
        end

        def metric_count_increment(database = 'telegraf', count = 0)
          key = "@#{database}_count".to_sym
          instance_variable_set(key, Concurrent::AtomicFixnum.new) unless instance_variable_defined?(key)

          global_metric_count_inc(count) unless count.zero?
          instance_variable_get(key).increment(count)
        end

        def global_metric_count=(count = 0)
          @global_metric_count.increment(count)
          global_metric_count
        end

        def global_metric_count_inc(count = 0)
          @global_metric_count.increment(count)
          global_metric_count
        end

        def global_metric_count
          @global_metric_count.value
        end

        def db_tag_location(consumer, database = 'telegraf')
          key = "@#{consumer}_#{database}_location".to_sym

          unless instance_variable_defined?(key)
            instance_variable_set(key, Concurrent::AtomicFixnum.new) unless instance_variable_defined?(key)
            return 0
          end

          tag_location = 0
          database_lock(database).with_read_lock do
            tag_location = instance_variable_get(key).value
          end

          tag_location
        end

        def db_tag_location_update(location, consumer, database = 'telegraf')
          key = "@#{consumer}_#{database}_location".to_sym
          database_lock(database).with_write_lock do
            instance_variable_set(key, Concurrent::AtomicFixnum.new) unless instance_variable_defined?(key)
            instance_variable_get(key).value = location
          end

          location
        end
      end
    end
  end
end
