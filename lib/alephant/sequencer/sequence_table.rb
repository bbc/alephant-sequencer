require "aws-sdk-dynamodb"
require 'thread'
require 'timeout'

require 'alephant/logger'
require 'alephant/support/dynamodb/table'

module Alephant
  module Sequencer
    class SequenceTable < ::Alephant::Support::DynamoDB::Table
      include Logger
      attr_reader :table_name, :client

      def initialize(table_name)
        options = {}
        options[:endpoint] = ENV['AWS_DYNAMO_DB_ENDPOINT'] if ENV['AWS_DYNAMO_DB_ENDPOINT']
        @mutex      = Mutex.new
        @client     = Aws::DynamoDB::Client.new(options)
        @table_name = table_name
      end

      def sequence_exists(ident)
        return false if ident.nil?

        !client.get_item(
          item_payload(ident)
        ).empty?
      end

      def sequence_for(ident)
        data = client.get_item(
          item_payload(ident)
        )

        !data.empty? ? data.item['value'].to_i : 0
      end

      def update_sequence_id(ident, value, last_seen_check = nil)
        current_sequence = last_seen_check.nil? ? sequence_for(ident) : last_seen_check

        dynamo_response = @mutex.synchronize do
          client.put_item(
            table_name: table_name,
            item: {
              'key'   => ident,
              'value' => value
            },
            condition_expression: ':current_value < :new_value',
            expression_attribute_values: {
              ':current_value' => current_sequence,
              ':new_value'     => value
            }
          )
        end

        logger.metric('SequencerFailedConditionalChecks', value: 0)
        logger.info(
          'event'  => 'SequenceIdUpdated',
          'id'     => ident,
          'value'  => value,
          'method' => "#{self.class}#update_sequence_id"
        )

        dynamo_response

      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException => e
        logger.metric 'SequencerFailedConditionalChecks'
        logger.error(
          'event'                => 'DynamoDBConditionalCheckFailed',
          'newSequenceValue'     => value,
          'currentSequenceValue' => current_sequence,
          'id'                   => ident,
          'class'                => e.class,
          'message'              => e.message,
          'backtrace'            => e.backtrace.join("\n"),
          'method'               => "#{self.class}#update_sequence_id"
        )
      end

      def delete_item!(ident)
        client.delete_item(
          item_payload(ident)
        )
      end

      private

      def item_payload(ident)
        {
          table_name: table_name,
          key:        {
            'key' => ident.to_s
          }
        }
      end
    end
  end
end
