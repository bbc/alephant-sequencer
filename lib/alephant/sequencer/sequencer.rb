require 'jsonpath'

require 'alephant/logger'

module Alephant
  module Sequencer
    class Sequencer
      include Logger
      attr_reader :ident, :jsonpath, :keep_all

      def initialize(sequence_table, id, sequence_path, keep_all = true)
        @sequence_table = sequence_table
        @sequence_table.create

        @keep_all = keep_all
        @exists   = exists?
        @jsonpath = sequence_path
        @ident    = id
      end

      def sequential?(msg)
        (get_last_seen || 0) < Sequencer.sequence_id_from(msg, jsonpath)
      end

      def exists?
        @exists || @sequence_table.sequence_exists(ident)
      end

      def sequence(msg, &block)
        last_seen_id = get_last_seen
        sequential = ((last_seen_id || 0) < Sequencer.sequence_id_from(msg, jsonpath))

        block.call(msg) if (sequential || keep_all)

        if sequential
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

      def truncate!
        @sequence_table.truncate!
      end

      def set_last_seen(msg, last_seen_check = nil)
        seen_id = Sequencer.sequence_id_from(msg, jsonpath)

        @sequence_table.set_sequence_for(
          ident, seen_id,
          (exists? ? last_seen_check : nil)
        )
      end

      def get_last_seen
        @sequence_table.sequence_for(ident)
      end

      def self.sequence_id_from(msg, path)
        JsonPath.on(msg.body, path).first.to_i
      end
    end
  end
end
