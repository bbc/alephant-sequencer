require 'spec_helper'

describe Alephant::Sequencer do
  let(:ident) { :ident }
  let(:jsonpath) { "$.sequence_id" }

  describe ".create(table_name, ident, jsonpath)" do
    it "should return a Sequencer" do
      Alephant::Sequencer::SequenceTable.any_instance.stub(:create)
      expect(subject.create(:table_name, ident, jsonpath)).to be_a Alephant::Sequencer::Sequencer
    end
  end

  describe Alephant::Sequencer::Sequencer do
    let(:data)     { double() }
    let(:last_seen) { 42 }

    def sequence_table
      table = double()
      table.stub(:create)
      table.stub(:sequence_exists)
      table.stub(:sequence_for)
      table.stub(:set_sequence_for)

      table
    end

    describe "#initialize(opts, id)" do
      it "sets @jsonpath, @ident" do
        subject = Alephant::Sequencer::Sequencer.new(sequence_table, ident, jsonpath)

        expect(subject.jsonpath).to eq(jsonpath)
        expect(subject.ident).to eq(ident)
      end

      it "calls create on sequence_table" do
        table = double()
        table.stub(:sequence_exists)
        table.should_receive(:create)

        Alephant::Sequencer::Sequencer.new(table, ident, jsonpath)
      end
    end


    describe "#sequence(msg, &block)" do
      let(:message) do
        m = double()
        m.stub(:body)

        m
      end

      let(:a_proc) do
        a_block = double()
        a_block.should_receive(:called).with(message)

        Proc.new do |msg|
          a_block.called(msg)
        end
      end

      let(:stubbed_last_seen) { 2 }
      let(:stubbed_seen_high) { 3 }
      let(:stubbed_seen_low)  { 1 }

      it "should call the passed block with msg" do
        subject = Alephant::Sequencer::Sequencer.new(sequence_table, ident, jsonpath)
        subject.sequence(message, &a_proc)
      end

      context "last_seen_id is nil" do
        before(:each) do
          Alephant::Sequencer::Sequencer.any_instance
            .stub(:get_last_seen).and_return(nil)

          Alephant::Sequencer::Sequencer
            .stub(:sequence_id_from).and_return(stubbed_seen_high)
        end

        it "should not call set_last_seen(msg, last_seen_id)" do
          Alephant::Sequencer::Sequencer.any_instance
            .should_receive(:set_last_seen)
            .with(message, nil)

          subject = Alephant::Sequencer::Sequencer.new(sequence_table, ident, jsonpath)
          subject.sequence(message, &a_proc)
        end
      end

      context "last_seen_id == sequence_id_from(msg)" do
        before(:each) do
          Alephant::Sequencer::Sequencer.any_instance
            .stub(:get_last_seen).and_return(stubbed_last_seen)

          Alephant::Sequencer::Sequencer
            .stub(:sequence_id_from).and_return(stubbed_last_seen)
        end

        it "should not call set_last_seen(msg, last_seen_id)" do
          Alephant::Sequencer::Sequencer.any_instance
            .should_not_receive(:set_last_seen)

          subject = Alephant::Sequencer::Sequencer.new(sequence_table, ident, jsonpath)
          subject.sequence(message, &a_proc)
        end
      end

      context "last_seen_id > sequence_id_from(msg)" do
        before(:each) do
          Alephant::Sequencer::Sequencer.any_instance
            .stub(:get_last_seen).and_return(stubbed_last_seen)

          Alephant::Sequencer::Sequencer.any_instance
            .stub(:sequence_id_from).and_return(stubbed_seen_low)
        end

        it "should not call set_last_seen(msg, last_seen_id)" do
          Alephant::Sequencer::Sequencer.any_instance
            .should_not_receive(:set_last_seen)

          subject = Alephant::Sequencer::Sequencer.new(sequence_table, ident, jsonpath)
          subject.sequence(message, &a_proc)
        end
      end

      context "last_seen_id < sequence_id_from(msg)" do
        before(:each) do
          Alephant::Sequencer::Sequencer.any_instance
            .stub(:get_last_seen).and_return(stubbed_last_seen)

          Alephant::Sequencer::Sequencer
            .stub(:sequence_id_from).and_return(stubbed_seen_high)
        end

        it "should call set_last_seen(msg, last_seen_id)" do
          Alephant::Sequencer::Sequencer.any_instance
            .should_receive(:set_last_seen)
            .with(message, stubbed_last_seen)

          subject = Alephant::Sequencer::Sequencer.new(sequence_table, ident, jsonpath)
          subject.sequence(message, &a_proc)
        end
      end
    end

    describe "#get_last_seen" do
      it "returns sequence_table.sequence_for(ident)" do
        table = double()
        table.stub(:sequence_exists)
        table.stub(:create)
        table.should_receive(:sequence_for).with(ident).and_return(:expected_value)

        expect(
          Alephant::Sequencer::Sequencer.new(table, ident, jsonpath).get_last_seen
        ).to eq(:expected_value)
      end
    end

    describe "#set_last_seen(data)" do
      before(:each) do
        Alephant::Sequencer::Sequencer.stub(:sequence_id_from).and_return(last_seen)
      end

      it "calls set_sequence_for(ident, last_seen)" do
        table = double()
        table.stub(:sequence_exists)
        table.stub(:create)
        table.stub(:sequence_for)
        table.should_receive(:set_sequence_for).with(ident, last_seen, nil)

        Alephant::Sequencer::Sequencer.new(table, ident, jsonpath).set_last_seen(data)
      end
    end

    describe ".sequence_id_from(data)" do
      subject { Alephant::Sequencer::Sequencer }
      it "should return the id described by the set jsonpath" do
        msg = Struct.new(:body).new({ "set_sequence_id" => 1 })
        expect(subject.sequence_id_from(msg,'$.set_sequence_id')).to eq(1)
      end
    end

    describe "#sequential?(data, jsonpath)" do

      before(:each) do
        Alephant::Sequencer::Sequencer.any_instance.stub(:get_last_seen).and_return(1)
        data.stub(:body).and_return('sequence_id' => id_value)
      end

      context "jsonpath = '$.sequence_id'" do
        let(:jsonpath) { '$.sequence_id' }
        subject { Alephant::Sequencer::Sequencer.new(sequence_table, :ident, jsonpath) }
        context "sequential" do
          let(:id_value) { 2 }
          it "is true" do
            expect(subject.sequential?(data)).to be_true
          end
        end

        context "nonsequential" do
          let(:id_value) { 0 }
          it "is false" do
            expect(subject.sequential?(data)).to be_false
          end
        end
      end

      context "jsonpath = nil" do
        let(:jsonpath) { '$.sequence_id' }
        subject { Alephant::Sequencer::Sequencer.new(sequence_table, :ident, jsonpath) }

        context "sequential" do
          let(:id_value) { 2 }
          it "is true" do
            expect(subject.sequential?(data)).to be_true
          end
        end

        context "nonsequential" do
          let(:id_value) { 0 }
          it "is false" do
            expect(subject.sequential?(data)).to be_false
          end
        end
      end

    end
  end
end
