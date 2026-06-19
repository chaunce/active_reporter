require "spec_helper"

describe ActiveReporter::Tracker::Base do
  let(:report) { double("report") }

  describe "#aggregator" do
    it "defaults to the tracker name" do
      expect(described_class.new(:likes, report).aggregator).to eq :likes
    end

    it "uses the configured :aggregator" do
      expect(described_class.new(:likes_delta, report, aggregator: :likes).aggregator).to eq :likes
    end
  end

  describe "#prior_aggregator" do
    it "defaults to the aggregator" do
      expect(described_class.new(:likes_delta, report, aggregator: :likes).prior_aggregator).to eq :likes
    end

    it "uses the configured :prior_aggregator" do
      tracker = described_class.new(:likes_delta, report, aggregator: :likes, prior_aggregator: :prior_likes)
      expect(tracker.prior_aggregator).to eq :prior_likes
    end
  end
end

describe ActiveReporter::Tracker::Value do
  let(:report) { double("report") }
  let(:tracker) { described_class.new(:prior_likes, report, aggregator: :likes) }

  describe "#track" do
    it "returns the prior row's aggregator value" do
      expect(tracker.track({ likes: 5 }, { likes: 3 })).to eq 3
    end

    it "returns nil when there is no prior row" do
      expect(tracker.track({ likes: 5 }, nil)).to be_nil
    end
  end
end

describe ActiveReporter::Tracker::Delta do
  let(:report) { double("report") }
  let(:tracker) { described_class.new(:likes_delta, report, aggregator: :likes) }

  describe "#track" do
    it "returns the percentage change from the prior row" do
      expect(tracker.track({ likes: 6 }, { likes: 4 })).to eq 150.0
    end

    it "returns nil when there is no prior row" do
      expect(tracker.track({ likes: 6 }, nil)).to be_nil
    end

    it "returns nil when the prior value is zero (avoids divide-by-zero)" do
      expect(tracker.track({ likes: 6 }, { likes: 0 })).to be_nil
    end
  end
end
