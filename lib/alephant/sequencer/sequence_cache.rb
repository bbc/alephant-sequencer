require "dalli-elasticache"
require "alephant/logger"

module Alephant
  module Sequencer
    class SequenceCache
      include Logger

      attr_reader :config

      DEFAULT_TTL  = 2

      def initialize(config={})
        @config = config

        unless config_endpoint.nil?
          @elasticache ||= ::Dalli::ElastiCache.new(config_endpoint, { :expires_in => ttl })
          @client ||= @elasticache.client
        else
          logger.debug "Alephant::SequenceCache::#initialize: No config endpoint, NullClient used"
          logger.metric "NoConfigEndpoint"
          @client = NullClient.new
        end
      end

      def get(key, &block)
        begin
          versioned_key = versioned key
          result = @client.get versioned_key
          logger.info "Alephant::SequenceCache#get key: #{versioned_key} - #{result ? 'hit' : 'miss'}"
          logger.metric "GetKeyMiss" unless result
          result ? result : set(key, block.call)
        rescue StandardError => e
          block.call
        end
      end

      def set(key, value, ttl = nil)
        value.tap { |o| @client.set(versioned(key), o, ttl) }
      end

      private

      def config_endpoint
        config[:elasticache_config_endpoint] || config["elasticache_config_endpoint"]
      end

      def ttl
        config[:sequencer_elasticache_ttl] || config["sequencer_elasticache_ttl"] || DEFAULT_TTL
      end

      def versioned(key)
        [key, cache_version].compact.join("_")
      end

      def cache_version
        config[:elasticache_cache_version] || config["elasticache_cache_version"]
      end
    end

    class NullClient
      def get(key); end

      def set(key, value, ttl = nil)
        value
      end
    end
  end
end