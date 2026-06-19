# frozen_string_literal: true

require "spec_helper"

# Exercises calculators, trackers, and (block) evaluators flowing through every
# data shaper (raw_data, flat_data, hashed_data, nested_data). The other report
# specs cover these shapers without those metric types, so this fills the
# calculable?/trackable?/evaluatable? branches. Calculators and trackers are
# exercised in separate reports because a single report combining both is not
# supported (the tracker's prior_bin_report drops the parent_report).
describe "ActiveReporter::Report data shapers" do
  let(:year) { 1.year.ago.year }

  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      count_aggregator :count
      sum_aggregator :likes
      number_dimension :likes
      category_dimension :author, model: :author, attribute: :name, relation: ->(r) { r.joins(:author) }
      time_dimension :created_at
      ratio_calculator :likes_ratio, aggregator: :likes
      delta_tracker :likes_delta, aggregator: :likes
      block_evaluator(:has_likes) { |_key, row, _report| row["likes"].to_i > 0 }
    end
  end

  let(:author) { create(:author, name: "Ann") }
  let!(:post_jan01) { create(:post, author: author, created_at: Date.new(year, 1, 1), likes: 2) }
  let!(:post_jan15) { create(:post, author: author, created_at: Date.new(year, 1, 15), likes: 3) }
  let!(:post_feb01) { create(:post, author: author, created_at: Date.new(year, 2, 1), likes: 4) }

  context "with trackers and evaluators" do
    let(:report) do
      report_model.new(
        groupers: %i[author created_at],
        dimensions: { created_at: { bin_width: { months: 1 } } },
        aggregators: %i[count likes],
        trackers: %i[likes_delta],
        evaluators: %i[has_likes]
      )
    end

    it "computes evaluator values in raw_data" do
      expect(report.raw_data.keys.map(&:last)).to include("has_likes")
    end

    it "includes evaluator output in nested_data" do
      has_likes_values = report.nested_data
        .flat_map { |author_group| author_group[:values] }
        .flat_map { |month_group| month_group[:values] }
        .select { |entry| entry[:key] == "has_likes" }
        .map { |entry| entry[:value] }

      expect(has_likes_values).to include(true)
    end

    it "includes tracker and evaluator keys in flat_data" do
      expect(report.flat_data.keys.map(&:last).uniq).to include("likes_delta", "has_likes")
    end

    it "includes tracker and evaluator keys in hashed_data" do
      expect(report.hashed_data.flat_map(&:keys).uniq).to include(:likes_delta, :has_likes)
    end
  end

  context "with calculators and evaluators" do
    let(:parent_report) { report_model.new(groupers: %i[author], aggregators: %i[count likes]) }
    let(:report) do
      report_model.new(
        groupers: %i[author created_at],
        dimensions: { created_at: { bin_width: { months: 1 } } },
        aggregators: %i[count likes],
        calculators: %i[likes_ratio],
        evaluators: %i[has_likes],
        parent_report: parent_report
      )
    end

    it "includes calculator and evaluator keys in flat_data" do
      expect(report.flat_data.keys.map(&:last).uniq).to include("likes_ratio", "has_likes")
    end

    it "includes calculator and evaluator keys in hashed_data" do
      expect(report.hashed_data.flat_map(&:keys).uniq).to include(:likes_ratio, :has_likes)
    end

    it "includes calculator and evaluator keys in nested_data" do
      keys = report.nested_data
        .flat_map { |author_group| author_group[:values] }
        .flat_map { |month_group| month_group[:values] }
        .map { |entry| entry[:key] }
        .uniq

      expect(keys).to include("likes_ratio", "has_likes")
    end
  end
end
