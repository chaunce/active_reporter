# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter::Serializer::Base do
  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      count_aggregator :post_count
      category_dimension :title
      number_dimension :likes
      time_dimension :created_at
    end
  end

  let(:dimensions) { {} }
  let(:report) { report_model.new(groupers: %i[title likes], dimensions: dimensions) }
  let(:serializer) { described_class.new(report) }

  let(:title_dimension) { report.dimensions[:title] }
  let(:likes_dimension) { report.dimensions[:likes] }
  let(:created_at_dimension) { report.dimensions[:created_at] }

  before { create(:post, title: "A", likes: 2) }

  describe "#human_aggregator_label" do
    it "humanizes and joins the aggregator names" do
      expect(serializer.human_aggregator_label(post_count: nil, likes_total: nil)).to eq "Post count Likes total"
    end
  end

  describe "#human_dimension_label" do
    it "humanizes the dimension name" do
      expect(serializer.human_dimension_label(created_at_dimension)).to eq "Created at"
    end
  end

  describe "#human_null_value_label" do
    it "prefixes the humanized dimension label with 'No'" do
      expect(serializer.human_null_value_label(title_dimension)).to eq "No Title"
    end
  end

  describe "#human_dimension_value_label" do
    it "returns the null label for nil values" do
      expect(serializer.human_dimension_value_label(title_dimension, nil)).to eq "No Title"
    end

    it "returns the raw value for category dimensions" do
      expect(serializer.human_dimension_value_label(title_dimension, "A")).to eq "A"
    end
  end

  describe "#human_number_value_label" do
    it "formats a closed bin as a half-open interval" do
      bin = ActiveReporter::Dimension::Number::Set.new(1, 3)
      expect(serializer.human_number_value_label(likes_dimension, bin)).to eq "[1.0, 3.0)"
    end

    it "formats a min-only bin with >=" do
      bin = ActiveReporter::Dimension::Number::Set.new(1, nil)
      expect(serializer.human_number_value_label(likes_dimension, bin)).to eq ">= 1.0"
    end

    it "formats a max-only bin with <" do
      bin = ActiveReporter::Dimension::Number::Set.new(nil, 3)
      expect(serializer.human_number_value_label(likes_dimension, bin)).to eq "< 3.0"
    end

    it "falls back to the null label for an empty bin" do
      bin = ActiveReporter::Dimension::Number::Set.new(nil, nil)
      expect(serializer.human_number_value_label(likes_dimension, bin)).to eq "No Likes"
    end
  end

  describe "#human_time_value_label" do
    it "formats a min-only bin with 'after'" do
      bin = ActiveReporter::Dimension::Time::Set.new("2015-06-01", nil)
      expect(serializer.human_time_value_label(created_at_dimension, bin)).to eq "after #{bin.min}"
    end

    it "formats a max-only bin with 'before'" do
      bin = ActiveReporter::Dimension::Time::Set.new(nil, "2015-06-01")
      expect(serializer.human_time_value_label(created_at_dimension, bin)).to eq "before #{bin.max}"
    end

    it "falls back to the null label for an empty bin" do
      bin = ActiveReporter::Dimension::Time::Set.new(nil, nil)
      expect(serializer.human_time_value_label(created_at_dimension, bin)).to eq "No Created at"
    end
  end

  describe "#human_dimension_value_label" do
    it "returns the raw value for dimensions that are not category/number/time" do
      other_dimension = double("dimension")
      expect(serializer.human_dimension_value_label(other_dimension, "raw")).to eq "raw"
    end
  end

  describe "#record_type" do
    it "is the humanized, singularized table name" do
      expect(serializer.record_type).to eq "Post"
    end
  end

  describe "#axis_summary" do
    it "summarizes the aggregators, groupers, and record count" do
      expect(serializer.axis_summary).to eq "Post count by Title and Likes for 1 Post"
    end
  end

  describe "#filter_summary" do
    let(:dimensions) { { title: { only: "A" } } }

    it "lists each active filter and its values" do
      expect(serializer.filter_summary).to eq "Title = A"
    end
  end
end
