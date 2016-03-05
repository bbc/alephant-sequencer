require "alephant/sequencer/version"
require "alephant/sequencer/sequencer"
require "alephant/sequencer/sequence_table"
require "alephant/sequencer/sequence_cache"

module Alephant
  module Sequencer
    @@sequence_tables = {}

    def self.create(table_name, ident, jsonpath = nil, keep_all = true, config = {})
      @@sequence_tables[table_name] ||= SequenceTable.new(table_name)
      @cache ||= SequenceCache.new(config)
      Sequencer.new(@@sequence_tables[table_name], ident, jsonpath, keep_all, @cache)
    end

  end
end
