require "spec_helper"

describe ActiveReporter::Aggregator::Ratio do
  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      category_dimension :title
      count_aggregator :count
    end
  end

  let(:report) { report_model.new(groupers: [:title]) }

  describe "#function" do
    it "builds a NULLIF-guarded float ratio of the two columns" do
      aggregator = described_class.new(:likes_per_id, report, numerator: :likes, denominator: :id)

      expect(aggregator.function).to eq "(posts.likes/NULLIF(posts.id,0)::FLOAT)"
    end

    it "raises when no numerator is configured" do
      aggregator = described_class.new(:ratio, report, {})

      expect { aggregator.function }.to raise_error(/must specify a numerator/)
    end

    it "raises when no denominator is configured" do
      aggregator = described_class.new(:ratio, report, numerator: :likes)

      expect { aggregator.function }.to raise_error(/must specify a denominator/)
    end
  end
end
