require 'zlib'

module Telemetry
  module Scriber
    module Compress
      def opts
        @opts ||= {}
      end

      def env_key
        'telemetry.scriber'
      end

      def default_window_bits
        @default_window_bits ||= if opts.key? :compression_window_bits
                                   opts[:compression_window_bits]
                                 elsif ENV.key? "#{env_key}.compression_window_bits"
                                   ENV["#{env_key}.compression_window_bits"].to_i
                                 else
                                   15
                                 end
      end

      def default_mem_level
        @default_mem_level ||= if opts.key? :compression_mem_level
                                 opts[:compression_mem_level]
                               elsif ENV.key? "#{env_key}.compression_mem_level"
                                 ENV["#{env_key}.compression_mem_level"].to_i
                               else
                                 9
                               end
      end

      def default_level
        @default_level ||= if opts.key? :compression_level
                             opts[:compression_level]
                           elsif ENV.key? "#{env_key}.compression_level"
                             ENV["#{env_key}.compression_level"].to_i
                           else
                             3
                           end
      end

      def use_ractor?
        @use_ractor ||= RUBY_VERSION[0].to_i >= 3
      end

      def compress(string, use_ractors: true, **)
        if use_ractors && use_ractor?
          Ractor.new(string) { |msg| ::Zlib::Deflate.new.deflate(msg) }
        else
          ::Zlib::Deflate.new(default_level, default_window_bits, default_mem_level).deflate(string)
        end
      end

      def decompress(payload, use_ractors: true, **)
        if use_ractors && use_ractor?
          Ractor.new(payload) { |msg| ::Zlib::Inflate.new(Zlib::MAX_WBITS + 32).inflate(msg) }.take
        else
          ::Zlib::Inflate.new(Zlib::MAX_WBITS + 32).inflate(payload)
        end
      end

      def deflate(level: default_level, window_bits: default_window_bits, mem_level: default_mem_level)
        @deflate ||= ::Zlib::Deflate.new(level, window_bits, mem_level)
      end

      def inflate
        @inflate ||= ::Zlib::Inflate.new(Zlib::MAX_WBITS + 32)
      end
    end
  end
end
