require "spec_helper"

describe ActiveReporter::Evaluator::Base do
  let(:report) { double("report") }

  describe "#initialize" do
    it "stores the name, report, and opts" do
      evaluator = described_class.new(:my_evaluator, report, foo: "bar")

      expect(evaluator.name).to eq :my_evaluator
      expect(evaluator.report).to eq report
      expect(evaluator.opts).to eq(foo: "bar")
    end

    it "defaults opts to an empty hash" do
      expect(described_class.new(:my_evaluator, report).opts).to eq({})
    end
  end

  describe "#default_value" do
    it "returns the configured :default_value" do
      expect(described_class.new(:e, report, default_value: 42).default_value).to eq 42
    end

    it "is nil when no :default_value is configured" do
      expect(described_class.new(:e, report).default_value).to be_nil
    end
  end
end

describe ActiveReporter::Evaluator::Block do
  let(:report) { double("report") }

  describe "#evaluate" do
    it "calls the configured block with the given argument" do
      evaluator = described_class.new(:doubler, report, block: ->(x) { x * 2 })

      expect(evaluator.evaluate(21)).to eq 42
    end

    it "passes multiple arguments through to the block" do
      evaluator = described_class.new(:adder, report, block: ->(a, b) { a + b })

      expect(evaluator.evaluate(3, 4)).to eq 7
    end

    it "raises KeyError when no :block is configured" do
      expect { described_class.new(:e, report).evaluate }.to raise_error(KeyError)
    end
  end
end
