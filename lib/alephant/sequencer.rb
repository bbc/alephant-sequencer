require "alephant/sequencer/version"
require "alephant/sequencer/sequencer"
require "alephant/sequencer/sequence_table"
require "alephant/sequencer/sequence_cache"

module Alephant
  module Sequencer
    @@sequence_tables = {}

    def self.create(table_name, opts = {})
      defaults = {
        :jsonpath => nil,
        :keep_all => true,
        :config => {}
      }

      opts = defaults.merge(opts)

      @@sequence_tables[table_name] ||= SequenceTable.new(table_name)
      @cache ||= SequenceCache.new(opts[:config])
      Sequencer.new(@@sequence_tables[table_name], opts[:ident], opts[:jsonpath], opts[:keep_all], @cache)
    end

  end
end
