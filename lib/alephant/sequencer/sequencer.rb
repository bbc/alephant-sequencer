require 'jsonpath'
require 'alephant/logger'

module Alephant
  module Sequencer
    class Sequencer
      include ::Alephant::Logger
      attr_reader :ident, :jsonpath

      def initialize(sequence_table, id, sequence_path)
        @mutex = Mutex.new
        @sequence_table = sequence_table
        @jsonpath = sequence_path
        @ident = id

        @sequence_table.create
      end

      def sequential?(msg)
        get_last_seen < sequence_id_from(msg)
      end

      def delete!
        logger.info("Sequencer.delete!: #{ident}")
        @sequence_table.delete_item!(ident)
      end

      def set_last_seen(msg)
        last_seen_id = sequence_id_from(msg)
        logger.info("Sequencer.set_last_seen: #{last_seen_id}")

        @sequence_table.set_sequence_for(ident, last_seen_id)
      end

      def get_last_seen
        @sequence_table.sequence_for(ident)
      end

      def sequence_id_from(msg)
        JsonPath.on(msg.body, jsonpath).first
      end
    end
  end
end
