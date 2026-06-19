# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter::Dimension::Enum do
  let(:report_model) { :post }
  let(:filter_values) { nil }
  let(:status_dimension_options) { { only: filter_values }.compact }
  let(:report) { OpenStruct.new(params: { dimensions: { status: status_dimension_options } }, groupers: [:status, :category], raw_data: raw_data) }

  let(:raw_data) do
    {
      ["published", "post_count"] => 5, ["published", "post_total"] => 500.00, ["published", "post_average"] => 100.00,
      ["archived", "post_count"] => 7, ["archived", "post_total"] => 530.25, ["archived", "post_average"] => 75.75,
    }
  end

  let(:enum_values) { { "draft" => 0, "unpublished" => 1, "published" => 2, "archived" => 3 } }
  let(:group_values) { ["published", "archived"] }
  let(:all_values) { enum_values.keys.unshift(nil) }

  let(:status_dimension) do
    # No stubbing of enum_values: this exercises the real Post.defined_enums lookup.
    dimension = ActiveReporter::Dimension::Enum.new(:status, report, { model: report_model, only: filter_values })
    report.groupers[report.groupers.index(:status)] = dimension if report.groupers.include?(:status)

    dimension
  end

  describe "#group_values" do
    context "when filtering" do
      let(:filter_values) { ["unpublished", "published", "archived"] }

      it "returns filter_values" do
        expect(status_dimension).to be_filtering
        expect(status_dimension.group_values).to eq filter_values
      end
    end

    it "returns group enum values" do
      expect(status_dimension).not_to be_filtering
      expect(status_dimension.group_values).to match group_values
    end
  end

  describe "#all_values" do
    it "returns model enum values" do
      expect(status_dimension.all_values).to match all_values
    end
  end

  describe "#filter" do
    let!(:published_post) { create(:post, status: :published) }
    let!(:draft_post) { create(:post, status: :draft) }

    context "with specific enum values" do
      let(:filter_values) { ["published"] }

      it "limits the relation to rows with the matching enum integer" do
        expect(status_dimension.filter(Post.all)).to contain_exactly(published_post)
      end
    end

    context "with an empty set of values" do
      let(:filter_values) { [] }

      it "matches nothing" do
        expect(status_dimension.filter(Post.all)).to be_empty
      end
    end

    context "with a value and nil" do
      let(:filter_values) { ["published", nil] }

      it "matches rows with the value or a null column" do
        # status is NOT NULL here, so only the published row matches, but this
        # exercises the "IS NULL OR IN (...)" branch.
        expect(status_dimension.filter(Post.all)).to contain_exactly(published_post)
      end
    end

    context "with only nil" do
      let(:filter_values) { [nil] }

      it "matches only rows with a null column (the IS NULL branch)" do
        expect(status_dimension.filter(Post.all)).to be_empty
      end
    end
  end

  describe "#enum?" do
    it "is true when the attribute is a model enum" do
      expect(status_dimension.send(:enum?)).to be true
    end
  end
end
