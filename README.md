# Alephant::Sequencer

Using DynamoDB consistent read to enforce message order from SQS.

[![Build
Status](https://travis-ci.org/BBC-News/alephant-sequencer.png)](https://travis-ci.org/BBC-News/alephant-sequencer)

[![Gem Version](https://badge.fury.io/rb/alephant-sequencer.png)](http://badge.fury.io/rb/alephant-sequencer)

## Installation

Add this line to your application's Gemfile:

    gem 'alephant-sequencer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install alephant-sequencer

## Usage

```rb

require 'alephant/sequencer'

#Optional JSONPath specifying location of sequence_id
sequence_id = '$.sequence_number'

sequencer = Alephant::Sequencer.create(table_name, sqs_queue_url, sequence_id)

# Data from SQS message
data = Struct.new(:body).new({:sequence_number => 3})

# Sets last seen id
sequencer.set_last_seen(data)

# Gets last seen id
sequencer.get_last_seen
# => 3

# Is the message sequential?
sequencer.sequential?(data)

# Reset sequence
sequencer.delete!
```

## Contributing
1. Fork it ( http://github.com/<my-github-username>/alephant-sequencer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
