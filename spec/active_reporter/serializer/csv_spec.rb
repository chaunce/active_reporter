require "spec_helper"
require "tempfile"

describe ActiveReporter::Serializer::Csv do
  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      number_dimension :likes
      time_dimension :created_at
      category_dimension :title
      count_aggregator :post_count
    end
  end

  let(:report) do
    report_model.new(
      aggregators: :post_count,
      groupers: %i[created_at likes title],
      dimensions: {
        created_at: { bin_width: "1 day" },
        likes: { bin_width: 1 }
      }
    )
  end

  let(:csv) { described_class.new(report) }

  before do
    create(:post, created_at: "2016-01-01", likes: 2, title: "A")
    create(:post, created_at: "2016-01-01", likes: 2, title: "A")
    create(:post, created_at: "2016-01-01", likes: 1, title: "B")
    create(:post, created_at: "2016-01-02", likes: 1, title: "A")
  end

  describe "#csv_text" do
    it "renders the headers followed by each formatted row" do
      rows = CSV.parse(csv.csv_text)

      expect(rows.first).to eq ["Created at", "Likes", "Title", "Post count"]
      expect(rows).to include(["2016-01-01", "[2.0, 3.0)", "A", "2"])
      expect(rows.size).to eq(csv.each_row.to_a.size + 1) # data rows + header
    end
  end

  describe "#filename" do
    it "is the parameterized caption with a .csv extension" do
      expect(csv.filename).to eq "post-count-by-created-at-likes-and-title-for-4-posts.csv"
    end
  end

  describe "#save" do
    it "writes the csv text to the given file" do
      Tempfile.create(["report", ".csv"]) do |file|
        csv.save(file.path)

        expect(File.read(file.path)).to eq csv.csv_text
      end
    end
  end
end
