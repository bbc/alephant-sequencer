require 'dalli'
require 'alephant/logger'

module Alephant
  module Sequencer
    class SequenceCache
      include Logger

      attr_reader :config

      DEFAULT_TTL = 2

      def initialize(config = {})
        @config = config
      end

      def get(key)
        versioned_key = versioned key
        result = client.get versioned_key
        logger.info(
          method: 'Alephant::SequenceCache#get',
          key:    versioned_key,
          result: result ? 'hit' : 'miss'
        )
        logger.metric 'GetKeyMiss' unless result
        result ? result : set(key, yield)
      rescue StandardError => error
        logger.error(
          method: 'Alephant::Sequencer::SequenceCache#get',
          error:  error
        )
        yield
      end

      def set(key, value, ttl = nil)
        value.tap { |o| client.set(versioned(key), o, ttl) }
      end

      private

      def client
        return @client ||= ::Dalli::Client.new(config_endpoint, expires_in: ttl) unless config_endpoint.nil?

        logger.error(
          method:  'Alephant::Sequencer::SequenceCache#initialize',
          message: 'No config endpoint, NullClient used'
        )
        logger.metric 'NoConfigEndpoint'
        @client = NullClient.new
      end

      def config_endpoint
        config[:elasticache_config_endpoint] || config['elasticache_config_endpoint']
      end

      def ttl
        config[:sequencer_elasticache_ttl] || config['sequencer_elasticache_ttl'] || DEFAULT_TTL
      end

      def versioned(key)
        [key, cache_version].compact.join('_')
      end

      def cache_version
        config[:elasticache_cache_version] || config['elasticache_cache_version']
      end
    end

    class NullClient
      def get(key); end

      def set(_key, value, _ttl = nil)
        value
      end
    end
  end
end
