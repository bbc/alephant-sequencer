require "jsonpath"
require "alephant/logger"

module Alephant
  module Sequencer
    class Sequencer
      include Logger
      attr_reader :ident, :jsonpath, :keep_all, :cache

      def initialize(sequence_table, opts = {})
        @sequence_table = sequence_table

        @cache    = opts[:cache]
        @keep_all = opts[:keep_all]
        @ident    = opts[:id]
        @exists   = exists?
        @jsonpath = opts[:jsonpath]
        logger.info(
          "event"         => "SequencerInitialized",
          "sequenceTable" => sequence_table,
          "jsonPath"      => @jsonpath,
          "id"            => @ident,
          "method"        => "#{self.class}#initialize"
        )
      end

      def sequential?(msg)
        (get_last_seen || 0) < Sequencer.sequence_id_from(msg, jsonpath)
      end

      def exists?
        @exists || cache.get(ident) do
          @sequence_table.sequence_exists(ident)
        end
      end

      def validate(msg, &block)
        last_seen_id = get_last_seen
        sequential = ((last_seen_id || 0) < Sequencer.sequence_id_from(msg, jsonpath))

        block.call if (sequential || keep_all)

        if sequential
          set_last_seen(msg, last_seen_id)
        else
          logger.metric "SequencerNonSequentialMessageCount"
          logger.info(
            "event"      => "NonSequentialMessageReceived",
            "id"         => ident,
            "lastSeenId" => last_seen_id,
            "method"     => "#{self.class}#validate"
          )
        end
      end

      def delete!
        @exists = false
        @sequence_table.delete_item!(ident).tap do
          logger.info(
            "event"  => "SequenceIdDeleted",
            "id"     => ident,
            "method" => "#{self.class}#delete!"
          )
        end
      end

      def truncate!
        @sequence_table.truncate!
      end

      def set_last_seen(msg, last_seen_check = nil)
        seen_id = Sequencer.sequence_id_from(msg, jsonpath)

        @sequence_table.update_sequence_id(
          ident, seen_id,
          (exists? ? last_seen_check : nil)
        )
      end

      def get_last_seen(key = ident)
        cache.get(key) do
          @sequence_table.sequence_for(key)
        end
      end

      def self.sequence_id_from(msg, path)
        JsonPath.on(msg.body, path).first.to_i
      end
    end
  end
end
