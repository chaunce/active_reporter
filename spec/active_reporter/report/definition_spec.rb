# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter::Report do
  describe ".available_dimensions / .available_groupers" do
    let(:report_model) do
      stub_const("DefinitionReport", Class.new(ActiveReporter::Report) do
        report_on :Post
        count_aggregator :count
        sum_aggregator :likes
        number_dimension :likes
        category_dimension :title
        ratio_calculator :likes_ratio, aggregator: :likes
        delta_tracker :likes_delta, aggregator: :likes
      end)
    end

    it "lists the declared dimensions" do
      expect(report_model.available_dimensions).to include(:likes, :title)
      expect(report_model.available_groupers).to eq report_model.available_dimensions
    end

    it "lists aggregators, calculators, and trackers together" do
      expect(report_model.available_aggregators).to contain_exactly(:count, :likes, :likes_ratio, :likes_delta)
    end
  end

  describe ".report_on" do
    it "raises a helpful error when given an unknown class" do
      expect {
        Class.new(ActiveReporter::Report) { report_on :ThisClassDoesNotExist }
      }.to raise_error(NameError, /cannot be used as `report_on` class/)
    end
  end

  describe ".report_model" do
    it "infers the model from the class name when report_on is not used" do
      stub_const("AuthorReport", Class.new(ActiveReporter::Report) do
        count_aggregator :count
        category_dimension :name
      end)

      expect(AuthorReport.report_model).to eq Author
    end
  end

  describe ".default_report_model" do
    it "infers the model from the class name" do
      stub_const("AuthorReport", Class.new(ActiveReporter::Report) { count_aggregator :count })

      expect(AuthorReport.default_report_model).to eq Author
    end

    it "raises a configuration hint when the name does not map to a model" do
      stub_const("NopeReport", Class.new(ActiveReporter::Report) { count_aggregator :count })

      expect { NopeReport.default_report_model }.to raise_error(NameError, /please configure `report_on`/)
    end
  end
end
