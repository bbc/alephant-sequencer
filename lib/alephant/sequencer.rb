require 'alephant/sequencer/version'
require 'alephant/sequencer/sequencer'
require 'alephant/sequencer/sequence_table'
require 'alephant/sequencer/sequence_cache'

module Alephant
  module Sequencer
    @@sequence_tables = {}

    def self.create(table_name, opts = {})
      defaults = {
        jsonpath: nil,
        keep_all: true,
        config:   {}
      }

      opts = defaults.merge(opts).tap do |opts|
        opts[:cache] = cache(opts[:config])
      end

      @@sequence_tables[table_name] ||= SequenceTable.new(table_name)
      Sequencer.new(@@sequence_tables[table_name], opts)
    end

    private

    def self.cache(config)
      @cache ||= SequenceCache.new(config)
    end
  end
end
