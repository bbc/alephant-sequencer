require "alephant/sequencer/version"
require "alephant/sequencer/sequencer"
require "alephant/sequencer/sequence_table"

module Alephant
  module Sequencer
    @@sequence_tables = {}

    def self.create(table_name, ident, jsonpath = nil, keep_all = true)
      @@sequence_tables[table_name] ||= SequenceTable.new(table_name)
      Sequencer.new(@@sequence_tables[table_name], ident, jsonpath, keep_all)
    end
  end
end
