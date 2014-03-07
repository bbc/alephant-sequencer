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
        block.call(msg)

        last_seen_id = get_last_seen
        if (last_seen_id || 0) < sequence_id_from(msg)
          set_last_seen(msg, last_seen_id)
        else
          logger.info("Sequencer#sequence nonsequential message for #{ident}")
        end
      end

      def delete!
        logger.info("Sequencer#delete!: #{ident}")
        @exists = false
        @sequence_table.delete_item!(ident)
      end

      def set_last_seen(msg, last_seen_check = nil)
        seen_id = sequence_id_from(msg)

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
