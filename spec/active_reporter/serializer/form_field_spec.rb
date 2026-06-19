# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter::Serializer::FormField do
  # FormField#prefix relies on the report class name, so the model needs a real
  # constant name rather than an anonymous class.
  let(:report_model) do
    stub_const("FormFieldReport", Class.new(ActiveReporter::Report) do
      report_on :Post
      count_aggregator :post_count
      sum_aggregator :likes_total, attribute: :likes
      category_dimension :title
      number_dimension :likes
      time_dimension :created_at
    end)
  end

  let(:report) do
    report_model.new(
      aggregators: %i[post_count likes_total],
      groupers: %i[title likes],
      dimensions: { likes: { bin_width: 1 } }
    )
  end

  let(:form_field) { described_class.new(report) }

  before { create(:post, title: "A", likes: 2) }

  describe "#aggregator_options" do
    it "pairs each aggregator's humanized label with its name" do
      expect(form_field.aggregator_options).to contain_exactly(
        ["Post count", :post_count],
        ["Likes total", :likes_total]
      )
    end
  end

  describe "#dimension_options" do
    it "pairs each dimension's humanized label with its name" do
      expect(form_field.dimension_options).to include(["Title", :title], ["Likes", :likes])
    end
  end

  describe "#prefix" do
    it "is the underscored report class name" do
      expect(form_field.prefix).to eq "form_field_report"
    end
  end

  describe "#css_class" do
    it "demodulizes, underscores, and dasherizes" do
      expect(form_field.css_class("ActiveReporter::Dimension::Category")).to eq "category"
    end
  end

  describe "#field_for" do
    it "builds an :only select for category dimensions" do
      html = form_field.field_for(report.dimensions[:title])

      expect(html).to include("form_field_report[dimensions][title][only]")
    end

    it "builds min/max/step inputs for bin dimensions" do
      html = form_field.field_for(report.dimensions[:likes])

      expect(html).to include("form_field_report[dimensions][likes][only][min]")
      expect(html).to include("form_field_report[dimensions][likes][only][max]")
      expect(html).to include("form_field_report[dimensions][likes][bin_width]")
    end
  end

  describe "#html_fields" do
    it "renders the full set of fields as html-safe output" do
      html = nil
      expect { html = form_field.html_fields }.not_to raise_error
      expect(html).to be_html_safe
      expect(html).to include("active-reporter-fields")
    end
  end
end
