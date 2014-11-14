require "aws-sdk"
require "thread"
require "timeout"

require "alephant/logger"
require "alephant/support/dynamodb/table"

module Alephant
  module Sequencer
    class SequenceTable < ::Alephant::Support::DynamoDB::Table
      include ::Alephant::Logger

      attr_reader :table_name, :client

      def initialize(table_name)
        @mutex      = Mutex.new
        @client     = AWS::DynamoDB::Client::V20120810.new
        @table_name = table_name
      end

      def sequence_exists(ident)
        if ident.nil?
          return false
        end

        !(client.get_item(
          item_payload(ident)
        ).length == 0)
      end

      def sequence_for(ident)
        data = client.get_item(
          item_payload(ident)
        )

        data.length > 0 ? data[:item]["value"][:n].to_i : 0
      end

      def set_sequence_for(ident, value, last_seen_check = nil)
        begin

          current_sequence = last_seen_check.nil? ? sequence_for(ident) : last_seen_check
          @mutex.synchronize do

            client.put_item({
              :table_name => table_name,
              :item => {
                'key' => {
                  'S' => ident
                },
                'value' => {
                  'N' => value.to_s
                }
              },
              :expected => {
                'key' => {
                  :comparison_operator => 'NULL'
                },
                'value' => {
                  :comparison_operator => 'GE',
                  :attribute_value_list => [
                    { 'N' => current_sequence.to_s }
                  ]
                }
              },
              :conditional_operator => 'OR'
            })
          end

          logger.info("SequenceTable#set_sequence_for: #{value} for #{ident} success!")
        rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
          logger.warn("SequenceTable#set_sequence_for: (Value to put: #{value}, existing: #{current_sequence}) #{ident} outdated!")
        end
      end

      def delete_item!(ident)
        client.delete_item(
          item_payload(ident)
        )
      end

      private

      def item_payload(ident)
        {
          :table_name => table_name,
          :key => {
            'key' => {
              'S' => ident.to_s
            }
          }
        }
      end

    end
  end
end
