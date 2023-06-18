require "spec_helper"

describe ActiveReporter::Serializer::NestedHash do
  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      number_dimension :likes
      time_dimension :created_at
      category_dimension :title
      count_aggregator :post_count
      sum_aggregator :likes_count, attribute: :likes
    end
  end

  let(:report) do
    report_model.new(
      aggregators: [:post_count, :likes_count],
      groupers: %i[title created_at],
      dimensions: { created_at: { bin_width: "1 day" } }
    )
  end

  let(:nested_hash_with_id) { ActiveReporter::Serializer::NestedHash.new(report) }
  let!(:data_records) do
    [
      create(:post, created_at: "2016-01-01", likes: 2, title: "A"),
      create(:post, created_at: "2016-01-01", likes: 2, title: "A"),
      create(:post, created_at: "2016-01-01", likes: 1, title: "B"),
      create(:post, created_at: "2016-01-02", likes: 1, title: "A"),
    ]
  end

  describe "#report" do
    it "builds report" do
      expect(nested_hash_with_id.table).to eq({
        "A" => {
          "2016-01-01 00:00:00 UTC" => { post_count: "2", likes_count: "4" },
          "2016-01-02 00:00:00 UTC" => { post_count: "1", likes_count: "1" },
        },
        "B" => {
          "2016-01-01 00:00:00 UTC" => { post_count: "1", likes_count: "1" },
          "2016-01-02 00:00:00 UTC" => { post_count: "0", likes_count: "0" },
        }
      })
    end
  end
end
