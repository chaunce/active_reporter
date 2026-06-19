require "spec_helper"

describe ActiveReporter::Aggregator::Base do
  let(:report) { double("report", report_model: Post, table_name: "posts") }

  describe "#enum?" do
    it "is false when the attribute is not a model enum" do
      expect(described_class.new(:likes, report).send(:enum?)).to be false
    end

    it "is true when the attribute is a model enum" do
      expect(described_class.new(:status, report).send(:enum?)).to be true
    end
  end
end
