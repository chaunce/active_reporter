require "spec_helper"

describe ActiveReporter::Aggregator::CountIf do
  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      category_dimension :author, model: :author, attribute: :name, relation: ->(r) { r.left_outer_joins(:author) }
      count_if_aggregator :published_count, column: :status, value: 2 # status enum: published == 2
      count_aggregator :count
    end
  end

  let(:report) { report_model.new(groupers: [:author], aggregators: %i[published_count count]) }

  let(:author_alice) { create(:author, name: "Alice") }
  let!(:published_one) { create(:post, author: author_alice, status: :published) }
  let!(:published_two) { create(:post, author: author_alice, status: :published) }
  let!(:draft) { create(:post, author: author_alice, status: :draft) }

  it "counts only the rows whose column matches the configured value" do
    expect(report.raw_data).to eq(
      ["Alice", "published_count"] => 2,
      ["Alice", "count"] => 3,
    )
  end

  describe "#default_value" do
    it "defaults to 0 so empty groups report a count rather than nil" do
      expect(report.aggregators[:published_count].default_value).to eq 0
    end
  end
end
