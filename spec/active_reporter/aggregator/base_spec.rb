# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter::Aggregator::Base do
  let(:report) { double("report", report_model: Post, table_name: "posts") }

  describe "#expression" do
    it "defaults to table.column" do
      expect(described_class.new(:likes, report).send(:expression)).to eq "posts.likes"
    end

    it "uses a raw :expression option verbatim when given" do
      aggregator = described_class.new(:gross, report, expression: "SUM(CASE WHEN x THEN 1 ELSE 0 END)")
      expect(aggregator.send(:expression)).to eq "SUM(CASE WHEN x THEN 1 ELSE 0 END)"
    end
  end

  describe "#enum?" do
    it "is false when the attribute is not a model enum" do
      expect(described_class.new(:likes, report).send(:enum?)).to be false
    end

    it "is true when the attribute is a model enum" do
      expect(described_class.new(:status, report).send(:enum?)).to be true
    end
  end
end
