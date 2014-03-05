require 'jsonpath'

require 'alephant/logger'

module Alephant
  module Sequencer
    class Sequencer
      include ::Alephant::Logger
      attr_reader :ident, :jsonpath

      def initialize(sequence_table, id, sequence_path)
        @sequence_table = sequence_table
        @sequence_table.create

        @exists = exists?
        @jsonpath = sequence_path
        @ident = id
      end

      def sequential?(msg)
        (get_last_seen || 0) < sequence_id_from(msg)
      end

      def exists?
        @exists || @sequence_table.sequence_exists(ident)
      end

      def sequence(msg, &block)
        unless(!sequential?(msg))
          last_seen_id = get_last_seen
          block.call(msg)
          set_last_seen(msg, last_seen_id)
        end
      end

      def delete!
        logger.info("Sequencer#delete!: #{ident}")
        @exists = false
        @sequence_table.delete_item!(ident)
      end

      def set_last_seen(msg, last_seen_check = nil)
        seen_id = sequence_id_from(msg)
        logger.info("Sequencer#set_last_seen: #{seen_id}")

        @sequence_table.set_sequence_for(
          ident, seen_id,
          (exists? ? last_seen_check : nil)
        )
      end

      def get_last_seen
        @sequence_table.sequence_for(ident)
      end

      def sequence_id_from(msg)
        JsonPath.on(msg.body, jsonpath).first.to_i
      end
    end
  end
end
