require "spec_helper"

describe Alephant::Sequencer do
  let(:ident)    { :ident }
  let(:jsonpath) { "$.sequence_id" }
  let(:sequence_table) { double(Alephant::Sequencer::SequenceTable) }
  let(:keep_all) { true }
  let(:config) { { "elasticache_config_endpoint" => "/foo" } }
  let(:cache) { Alephant::Sequencer::SequenceCache.new(config) }
  let(:opts) {
    {
      :id => ident,
      :jsonpath => jsonpath,
      :keep_all => keep_all,
      :cache => cache
    }
  }

  describe ".create" do
    it "should return a Sequencer" do
      expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
      expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

      expect_any_instance_of(Alephant::Sequencer::SequenceTable).to receive(:initialize)
      expect_any_instance_of(Alephant::Sequencer::SequenceTable).to receive(:sequence_exists)

      opts = {
        :id => ident,
        :jsonpath => jsonpath,
        :keep_all => keep_all,
        :config => config
      }

      expect(subject.create(:table_name, opts)).to be_a Alephant::Sequencer::Sequencer
    end

    it "should use default opts if options not provided" do
      expect_any_instance_of(Alephant::Sequencer::SequenceTable).to receive(:sequence_exists)

      opts = {
        :id => ident
      }

      instance = subject.create(:table_name, opts)

      expect(instance).to be_a Alephant::Sequencer::Sequencer
      expect(instance.ident).to eq(ident)
      expect(instance.jsonpath).to eq(nil)
      expect(instance.keep_all).to eq(true)
      expect(instance.cache).to be_a(Alephant::Sequencer::SequenceCache)
    end
  end

  describe Alephant::Sequencer::Sequencer do
    let(:data)      { double() }
    let(:last_seen) { 42 }

    describe "#initialize" do
      subject (:instance) {
        described_class.new(sequence_table, opts)
      }

      it "sets @jsonpath, @ident" do
        expect(sequence_table).to receive(:sequence_exists)

        expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
        expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

        expect(instance.jsonpath).to eq(jsonpath)
        expect(instance.ident).to eq(ident)
        expect(instance.keep_all).to eq(true)
      end

    end

    describe "#validate" do
      let(:message) { double() }

      let(:an_uncalled_proc) do
        a_block = double()
        expect(a_block).to_not receive(:called).with(message)

        Proc.new do |msg|
          a_block.called(msg)
        end
      end

      let(:a_proc) do
        a_block = double()
        expect(a_block).to receive(:called)

        Proc.new do
          a_block.called
        end
      end

      let(:stubbed_last_seen) { 2 }
      let(:stubbed_seen_high) { 3 }
      let(:stubbed_seen_low)  { 1 }

      subject (:instance) {
        described_class.new(sequence_table, opts)
      }

      it "should call the passed block" do
        expect(sequence_table).to receive(:sequence_exists)
        expect(sequence_table).to receive(:sequence_for).with(ident)

        expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
        expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

        expect_any_instance_of(Dalli::Client).to receive(:get).twice
        expect_any_instance_of(Dalli::Client).to receive(:set).twice

        expect(message).to receive(:body)

        instance.validate(message, &a_proc)
      end

      context "last_seen_id is nil" do
        before(:each) do
          expect_any_instance_of(described_class).to receive(:get_last_seen).and_return(nil)

          expect(described_class).to receive(:sequence_id_from).and_return(stubbed_seen_high)

          expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
          expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

          expect_any_instance_of(Dalli::Client).to receive(:get)
          expect_any_instance_of(Dalli::Client).to receive(:set)
        end

        it "should not call set_last_seen" do
          expect_any_instance_of(described_class).to receive(:set_last_seen).with(message, nil)

          expect(sequence_table).to receive(:sequence_exists)

          instance.validate(message, &a_proc)
        end
      end

      context "last_seen_id == sequence_id_from(msg)" do
        before(:each) do
          expect_any_instance_of(described_class).to receive(:get_last_seen).and_return(stubbed_last_seen)

          expect(described_class).to receive(:sequence_id_from).and_return(stubbed_last_seen)

          expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
          expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

          expect_any_instance_of(Dalli::Client).to receive(:get)
          expect_any_instance_of(Dalli::Client).to receive(:set)
        end

        it "should not call set_last_seen(msg, last_seen_id)" do
          expect_any_instance_of(described_class).to_not receive(:set_last_seen)

          expect(sequence_table).to receive(:sequence_exists)

          instance.validate(message, &a_proc)
        end
      end

      context "last_seen_id > sequence_id_from(msg)" do
        before(:each) do
          expect_any_instance_of(described_class).to receive(:get_last_seen).and_return(stubbed_last_seen)

          expect(described_class).to receive(:sequence_id_from).and_return(stubbed_seen_low)

          expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
          expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

          expect_any_instance_of(Dalli::Client).to receive(:get)
          expect_any_instance_of(Dalli::Client).to receive(:set)
        end

        it "should not call set_last_seen" do
          expect_any_instance_of(described_class).to_not receive(:set_last_seen)

          expect(sequence_table).to receive(:sequence_exists)

          instance.validate(message, &a_proc)
        end

        context "keep_all is false" do
          let(:keep_all) { false }

          it "should not call the passed block with msg" do
            expect(sequence_table).to receive(:sequence_exists)

            opts = {
              :id => ident,
              :jsonpath => jsonpath,
              :keep_all => keep_all,
              :cache => cache
            }

            instance = described_class.new(sequence_table, opts)
            instance.validate(message, &an_uncalled_proc)
          end
        end
      end

      context "last_seen_id < sequence_id_from(msg)" do
        before(:each) do
          expect_any_instance_of(described_class).to receive(:get_last_seen).and_return(stubbed_last_seen)

          expect(described_class).to receive(:sequence_id_from).and_return(stubbed_seen_high)

          expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
          expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

          expect_any_instance_of(Dalli::Client).to receive(:get)
          expect_any_instance_of(Dalli::Client).to receive(:set)
        end

        it "should call set_last_seen(msg, last_seen_id)" do
          expect_any_instance_of(described_class).to receive(:set_last_seen).with(message, stubbed_last_seen)

          expect(sequence_table).to receive(:sequence_exists)

          instance.validate(message, &a_proc)
        end
      end

      context "values already in cache" do
        before(:each) do
          expect(message).to receive(:body).and_return("sequence_id" => 5)

          expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
          expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

          expect_any_instance_of(Dalli::Client).to receive(:get).twice.with("ident").and_return(stubbed_last_seen)
          expect_any_instance_of(Dalli::Client).to_not receive(:set)
        end

        it "should read values from cache and not database" do
          expect(sequence_table).to_not receive(:sequence_for)
          expect(sequence_table).to_not receive(:sequence_exists)

          expect_any_instance_of(described_class).to receive(:set_last_seen).with(message, stubbed_last_seen)

          instance.validate(message, &a_proc)
        end
      end
    end

    describe "#get_last_seen" do
      subject (:instance) {
        described_class.new(sequence_table, opts)
      }

      it "returns sequence_table.sequence_for(ident)" do
        expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
        expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

        expect_any_instance_of(Dalli::Client).to receive(:get).twice
        expect_any_instance_of(Dalli::Client).to receive(:set).twice

        expect(sequence_table).to receive(:sequence_exists)

        expect(sequence_table).to receive(:sequence_for)
          .with(ident)
          .and_return(:expected_value)

        expect(instance.get_last_seen).to eq(:expected_value)
      end
    end

    describe "#set_last_seen" do
      before(:each) do
        expect(described_class).to receive(:sequence_id_from).and_return(last_seen)

        expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
        expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

        expect_any_instance_of(Dalli::Client).to receive(:get).twice
        expect_any_instance_of(Dalli::Client).to receive(:set).twice
      end

      subject (:instance) {
        described_class.new(sequence_table, opts)
      }

      it "calls update_sequence_id(ident, last_seen)" do
        expect(sequence_table).to receive(:sequence_exists).twice

        expect(sequence_table).to receive(:update_sequence_id)
          .with(ident, last_seen, nil)

        instance.set_last_seen(data)
      end
    end

    describe ".sequence_id_from" do
      it "should return the id described by the set jsonpath" do
        msg = Struct.new(:body).new("set_sequence_id" => 1)

        expect(described_class.sequence_id_from(msg, "$.set_sequence_id")).to eq(1)
      end
    end

    describe "#sequential?" do
      before(:each) do
        expect_any_instance_of(described_class).to receive(:get_last_seen).and_return(1)

        expect(data).to receive(:body)
          .and_return("sequence_id" => id_value)

        expect(sequence_table).to receive(:sequence_exists)

        expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
        expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

        expect_any_instance_of(Dalli::Client).to receive(:get)
        expect_any_instance_of(Dalli::Client).to receive(:set)
      end

      subject (:instance) {
        described_class.new(sequence_table, opts)
      }

      context "jsonpath = '$.sequence_id'" do
        let(:jsonpath) { "$.sequence_id" }

        context "sequential" do
          let(:id_value) { 2 }

          it "is true" do
            expect(instance.sequential?(data)).to be
          end
        end

        context "nonsequential" do
          let(:id_value) { 0 }

          it "is false" do
            expect(instance.sequential?(data)).to be false
          end
        end
      end

      context "jsonpath = nil" do
        let(:jsonpath) { "$.sequence_id" }

        context "sequential" do
          let(:id_value) { 2 }

          it "is true" do
            expect(instance.sequential?(data)).to be
          end
        end

        context "nonsequential" do
          let(:id_value) { 0 }

          it "is false" do
            expect(instance.sequential?(data)).to be false
          end
        end
      end
    end

    describe "#truncate!" do
      subject (:instance) {
        described_class.new(sequence_table, opts)
      }

      it "verify SequenceTable#truncate!" do
        expect_any_instance_of(Dalli::ElastiCache).to receive(:initialize)
        expect_any_instance_of(Dalli::ElastiCache).to receive(:client).and_return(Dalli::Client.new)

        expect(sequence_table).to receive(:sequence_exists)
        expect(sequence_table).to receive(:truncate!)

        instance.truncate!
      end
    end
  end
end
