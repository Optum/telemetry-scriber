require 'telemetry/scriber/defaults'

module Telemetry
  module Scriber
    module Writer
      module Defaults
        include Telemetry::Scriber::Defaults

        def host
          opts[:host] || ENV["#{env_key}.writer.host"] || 'localhost'
        end

        def port
          if opts.key? :port
            opts[:port]
          elsif ENV.key? "#{env_key}.writer.port"
            ENV["#{env_key}.writer.port"].to_i
          else
            8086
          end
        end

        def username
          @username ||= if opts.key? :username
                          opts[:username]
                        elsif ENV.key? "#{env_key}.writer.username"
                          ENV["#{env_key}.writer.username"]
                        end
        end

        def password
          @password ||= if opts.key? :password
                          opts[:password]
                        elsif ENV.key? "#{env_key}.writer.password"
                          ENV["#{env_key}.writer.password"]
                        end
        end

        def pool_size
          @pool_size ||= if opts.key? :pool_size
                           opts[:pool_size]
                         elsif ENV.key? "#{env_key}.writer.pool_size"
                           ENV["#{env_key}.writer.pool_size"].to_i
                         else
                           2
                         end
        end

        def idle_timeout
          @idle_timeout ||= if opts.key? :idle_timeout
                              opts[:idle_timeout]
                            elsif ENV.key? "#{env_key}.writer.idle_timeout"
                              ENV["#{env_key}.writer.idle_timeout"].to_i
                            else
                              30
                            end
        end

        def write_timeout
          @write_timeout ||= if opts.key? :write_timeout
                               opts[:write_timeout]
                             elsif ENV.key? "#{env_key}.writer.write_timeout"
                               ENV["#{env_key}.writer.write_timeout"].to_i
                             else
                               10
                             end
        end

        def open_timeout
          @open_timeout ||= if opts.key? :open_timeout
                              opts[:open_timeout]
                            elsif ENV.key? "#{env_key}.writer.open_timeout"
                              ENV["#{env_key}.writer.open_timeout"].to_i
                            else
                              10
                            end
        end

        def max_retries
          @max_retries ||= if opts.key? :max_retries
                             opts[:max_retries]
                           elsif ENV.key? "#{env_key}.writer.max_retries"
                             ENV["#{env_key}.writer.max_retries"].to_i
                           else
                             10
                           end
        end

        def retry?
          @retry ||= if opts.key? :retry
                       opts[:retry]
                     elsif ENV.key? "#{env_key}.writer.retry"
                       ENV["#{env_key}.writer.retry"] == 'true' || ENV["#{env_key}.writer.retry"] == '1'
                     else
                       false
                     end
        end

        def retry_options
          {}
        end

        def ssl_options
          { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        end
      end
    end
  end
end
