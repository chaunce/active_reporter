require "spec_helper"

describe ActiveReporter::Serializer::Highcharts do
  let(:report_model) do
    Class.new(ActiveReporter::Report) do
      report_on :Post
      number_dimension :likes
      time_dimension :created_at
      category_dimension :title
      count_aggregator :post_count
    end
  end

  let(:chart) do
    ActiveReporter::Serializer::Highcharts.new(report)
  end

  before do
    create(:post, created_at: "2016-01-01", likes: 2, title: "A")
    create(:post, created_at: "2016-01-01", likes: 2, title: "A")
    create(:post, created_at: "2016-01-01", likes: 1, title: "B")
    create(:post, created_at: "2016-01-02", likes: 1, title: "A")
  end

  def y_values(series)
    series[:data].map { |d| d[:y] }
  end

  def filters(series)
    series[:data].map { |d| d[:filters] }
  end

  describe "#series" do
    context "with one grouper" do
      let(:report) do
        report_model.new(aggregators: :post_count, groupers: %i[title])
      end

      it "returns one series of the y values (with filters)" do
        expect(chart.series.count).to eq 1
        expect(y_values(chart.series[0])).to eq [3, 1]
        expect(filters(chart.series[0])).to eq [{ title: "A" }, { title: "B" }]
      end
    end

    context "with two groupers" do
      let(:report) do
        report_model.new(
          aggregators: :post_count,
          groupers: %i[title likes],
          dimensions: { likes: { bin_width: 1 } }
        )
      end

      it "returns one series for each x_2 value" do
        expect(chart.series.count).to eq 2
        expect(y_values(chart.series[0])).to eq [1, 1]
        expect(filters(chart.series[0])).to eq [
          { title: "A", likes: { min: 1, max: 2 } },
          { title: "B", likes: { min: 1, max: 2 } }
        ]
        expect(y_values(chart.series[1])).to eq [2, 0]
        expect(filters(chart.series[1])).to eq [
          { title: "A", likes: { min: 2, max: 3 } },
          { title: "B", likes: { min: 2, max: 3 } }
        ]
      end
    end

    context "with three groupers" do
      let(:report) do
        report_model.new(
          aggregators: :post_count,
          groupers: %i[title likes created_at],
          dimensions: {
            likes: { bin_width: 1 },
            created_at: { bin_width: "1 day" }
          }
        )
      end

      it "returns stacks for each x_3 of groups for each x_2" do
        expect(chart.series.count).to eq 4

        expect(chart.series[0][:stack]).to eq "2016-01-01"
        expect(chart.series[1][:stack]).to eq "2016-01-01"
        expect(chart.series[2][:stack]).to eq "2016-01-02"
        expect(chart.series[3][:stack]).to eq "2016-01-02"

        expect(chart.series[0][:id]).to eq "[1.0, 2.0)"
        expect(chart.series[1][:id]).to eq "[2.0, 3.0)"
        expect(chart.series[2][:linkedTo]).to eq "[1.0, 2.0)"
        expect(chart.series[3][:linkedTo]).to eq "[2.0, 3.0)"

        colors = chart.series.map { |s| s[:color] }
        expect(colors.all?(&:present?)).to be true
        expect(colors[0]).to eq colors[2]
        expect(colors[1]).to eq colors[3]
        expect(colors[0]).not_to eq colors[1]

        expect(y_values(chart.series[0])).to eq [0, 1]

        jan1 = Time.zone.parse("2016-01-01")
        jan2 = Time.zone.parse("2016-01-02")

        expect(filters(chart.series[0])).to eq [
          { title: "A", likes: { min: 1.0, max: 2.0 }, created_at: { min: jan1, max: jan2 } },
          { title: "B", likes: { min: 1.0, max: 2.0 }, created_at: { min: jan1, max: jan2 } }
        ]
      end
    end

    context "with multiple aggregators" do
      let(:report_model) do
        Class.new(ActiveReporter::Report) do
          report_on :Post
          category_dimension :title
          number_dimension :likes
          count_aggregator :post_count
          sum_aggregator :likes_total, attribute: :likes
        end
      end

      let(:report) do
        report_model.new(aggregators: %i[post_count likes_total], groupers: %i[title])
      end

      it "emits one series per aggregator" do
        expect(chart.series.map { |s| s[:name] }).to contain_exactly("Post count", "Likes total")

        post_count = chart.series.detect { |s| s[:name] == "Post count" }
        likes_total = chart.series.detect { |s| s[:name] == "Likes total" }

        expect(y_values(post_count)).to eq [3, 1]  # title A: 3 posts, title B: 1 post
        expect(y_values(likes_total)).to eq [5, 1] # title A: 2+2+1 likes, title B: 1 like
      end

      context "with a second grouper" do
        let(:report) do
          report_model.new(
            aggregators: %i[post_count likes_total],
            groupers: %i[title likes],
            dimensions: { likes: { bin_width: 1 } }
          )
        end

        it "suffixes each series name with the aggregator" do
          expect(chart.series.map { |s| s[:name] }).to all(match(/\((Post count|Likes total)\)\z/))
        end
      end
    end
  end

  describe "#series with too many groupers" do
    let(:report_model) do
      Class.new(ActiveReporter::Report) do
        report_on :Post
        category_dimension :title
        category_dimension :author, model: :author, attribute: :name, relation: ->(r) { r.joins(:author) }
        number_dimension :likes
        time_dimension :created_at
        count_aggregator :post_count
      end
    end

    let(:report) do
      report_model.new(
        aggregators: :post_count,
        groupers: %i[title author likes created_at],
        dimensions: { likes: { bin_width: 1 }, created_at: { bin_width: "1 day" } }
      )
    end

    it "raises when there are more than three groupers" do
      expect { chart.series }.to raise_error(ActiveReporter::InvalidParamsError, /<= 3 groupers/)
    end
  end

  describe "#highcharts_options" do
    let(:report) do
      report_model.new(aggregators: :post_count, groupers: %i[title])
    end

    it "builds a column-chart option hash with titles, axes, and series" do
      options = chart.highcharts_options

      expect(options[:chart][:type]).to eq "column"
      expect(options[:title][:text]).to eq chart.chart_title
      expect(options[:xAxis][:categories]).to eq chart.categories
      expect(options[:xAxis][:title][:text]).to eq "Title"
      expect(options[:yAxis][:title][:text]).to eq "Post count"
      expect(options[:series]).to eq chart.series
    end
  end
end
