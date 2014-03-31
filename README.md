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
require "alephant/sequencer"

# Ensure you check your AWS region configuration before you start
# For example: AWS.config(region: 'eu-west-1')

table_name   = "foo"
component_id = "bar_baz/e8c81cbbbeb3967a423bb49e352eed0e"
sequence_id  = "$.sequence_number" # Optional JSONPath (specifying location of sequence_id)

sequencer = Alephant::Sequencer.create(table_name, component_id, sequence_id)

# Data from SQS message
json = JSON.generate({ :sequence_number => 3 })
msg  = Struct.new(:body).new(json)

# Sets last seen id
sequencer.set_last_seen(msg)

# Gets last seen id
sequencer.get_last_seen
# => 3

# Is the message sequential?
sequencer.sequential?(msg)

# Reset sequence
sequencer.delete!
```

## Contributing
1. Fork it ( http://github.com/<my-github-username>/alephant-sequencer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
