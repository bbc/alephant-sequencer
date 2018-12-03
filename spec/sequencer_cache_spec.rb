require 'spec_helper'

describe Alephant::Sequencer::SequenceCache do

  subject (:instance) do
    described_class.new(config)
  end

  describe 'does not have elasticache config endpoint' do
    let(:config) { {} }

    it 'uses a null client' do
      expect_any_instance_of(Alephant::Sequencer::NullClient).to receive(:set)
      instance.set 'fake-key', 'some value'
    end
  end

  describe 'has elasticache config endpoint' do
    let(:config) { { 'elasticache_config_endpoint' => '/foo' } }

    it 'uses Dalli cache client' do
      expect_any_instance_of(Dalli::Client).to receive(:set)
      instance.set 'fake-key', 'some value'
    end
  end
end