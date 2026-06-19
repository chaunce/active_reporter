require "spec_helper"

describe ActiveReporter::Report do
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
    end
  end

  let(:groupers) { nil }
  let(:aggregators) { nil }
  let(:dimensions) { nil }
  let(:parent_report) { nil }
  let(:parent_groupers) { nil }
  let(:calculators) { nil }
  let(:trackers) { nil }
  let(:report) { report_model.new({groupers: groupers, aggregators: aggregators, dimensions: dimensions, parent_report: parent_report, parent_groupers: parent_groupers, calculators: calculators, trackers: trackers}.compact) }

  let(:year) { 1.year.ago.year }

  let(:jan_datetime) { Time.new(year,1,1,0,0,0,0) }
  let(:feb_datetime) { Time.new(year,2,1,0,0,0,0) }
  let(:mar_datetime) { Time.new(year,3,1,0,0,0,0) }
  let(:apr_datetime) { Time.new(year,4,1,0,0,0,0) }

  let(:jan) { { min: jan_datetime, max: jan_datetime.next_month } }
  let(:feb) { { min: feb_datetime, max: feb_datetime.next_month } }
  let(:mar) { { min: mar_datetime, max: mar_datetime.next_month } }
  let(:apr) { { min: apr_datetime, max: apr_datetime.next_month } }

  describe ".autoreport_on" do
    let(:report_model) { Class.new(ActiveReporter::Report) { autoreport_on :Post } }

    it "infers dimensions from columns" do
      expect(report_model.dimensions.keys).to include(*%i[created_at updated_at title author likes])
    end

    it "should properly store created_at dimension class" do
      expect(report_model.dimensions[:created_at][:axis_class]).to eq ActiveReporter::Dimension::Time
    end

    it "should properly store updated_at dimension class" do
      expect(report_model.dimensions[:updated_at][:axis_class]).to eq ActiveReporter::Dimension::Time
    end

    it "should properly store likes dimension class" do
      expect(report_model.dimensions[:likes][:axis_class]).to eq ActiveReporter::Dimension::Number
    end

    it "should properly store title dimension class" do
      expect(report_model.dimensions[:title][:axis_class]).to eq ActiveReporter::Dimension::Category
    end

    it "should properly store author dimension class" do
      expect(report_model.dimensions[:author][:axis_class]).to eq ActiveReporter::Dimension::Category
    end

    context "with expression" do
      let!(:report_model) do
        Class.new(ActiveReporter::Report) do
          report_on :Post
          count_aggregator :count
          sum_aggregator :likes
          number_dimension :likes
          category_dimension :author, expression: "authors.name", relation: ->(r) { r.joins(:author) }
          time_dimension :created_at
          ratio_calculator :likes_ratio, aggregator: :likes
          delta_tracker :likes_delta, aggregator: :likes
        end
      end

      it "should properly store author expression" do
        expect(report_model.dimensions[:author][:opts][:expression]).to eq "authors.name"
      end
    end
  end

  describe "data access" do
    let(:groupers) { %w(author created_at) }
    let(:dimensions) { { created_at: { bin_width: { months: 1 }, only: { min: Date.new(year,1,1).to_s }}} }

    let(:author_tammy) { create(:author, name: "Tammy") }
    let(:author_timmy) { create(:author, name: "Timmy") }

    let!(:post_tammy_dec18) { create(:post, author: author_tammy, created_at: Date.new(year.pred,12,18), likes: 23) }
    let!(:post_tammy_jan01) { create(:post, author: author_tammy, created_at: Date.new(year,1,1), likes: 7) }
    let!(:post_tammy_jan12) { create(:post, author: author_tammy, created_at: Date.new(year,1,12), likes: 4) }
    let!(:post_tammy_mar08) { create(:post, author: author_tammy, created_at: Date.new(year,3,8), likes: 11) }

    let!(:post_timmy_jan15) { create(:post, author: author_timmy, created_at: Date.new(year,1,15), likes: 3) }
    let!(:post_timmy_feb27) { create(:post, author: author_timmy, created_at: Date.new(year,2,27), likes: 24) }
    let!(:post_timmy_feb28) { create(:post, author: author_timmy, created_at: Date.new(year,2,28), likes: 0) }
    let!(:post_timmy_mar01) { create(:post, author: author_timmy, created_at: Date.new(year,3,1), likes: 19) }
    let!(:post_timmy_apr08) { create(:post, author: author_timmy, created_at: Date.new(year,4,8), likes: 8) }

    let(:author_tammy_dec_posts) { [post_tammy_dec18] }
    let(:author_tammy_jan_posts) { [post_tammy_jan01, post_tammy_jan12] }
    let(:author_tammy_feb_posts) { [] }
    let(:author_tammy_mar_posts) { [post_tammy_mar08] }
    let(:author_tammy_apr_posts) { [] }

    let(:author_timmy_dec_posts) { [] }
    let(:author_timmy_jan_posts) { [post_timmy_jan15] }
    let(:author_timmy_feb_posts) { [post_timmy_feb27, post_timmy_feb28] }
    let(:author_timmy_mar_posts) { [post_timmy_mar01] }
    let(:author_timmy_apr_posts) { [post_timmy_apr08] }

    let(:author_tammy_dec_count) { author_tammy_dec_posts.count }
    let(:author_tammy_jan_count) { author_tammy_jan_posts.count }
    let(:author_tammy_feb_count) { author_tammy_feb_posts.count }
    let(:author_tammy_mar_count) { author_tammy_mar_posts.count }
    let(:author_tammy_apr_count) { author_tammy_apr_posts.count }

    let(:author_timmy_dec_count) { author_timmy_dec_posts.count }
    let(:author_timmy_jan_count) { author_timmy_jan_posts.count }
    let(:author_timmy_feb_count) { author_timmy_feb_posts.count }
    let(:author_timmy_mar_count) { author_timmy_mar_posts.count }
    let(:author_timmy_apr_count) { author_timmy_apr_posts.count }

    let(:author_tammy_dec_likes) { author_tammy_dec_posts.sum(&:likes) }
    let(:author_tammy_jan_likes) { author_tammy_jan_posts.sum(&:likes) }
    let(:author_tammy_feb_likes) { author_tammy_feb_posts.sum(&:likes) }
    let(:author_tammy_mar_likes) { author_tammy_mar_posts.sum(&:likes) }
    let(:author_tammy_apr_likes) { author_tammy_apr_posts.sum(&:likes) }

    let(:author_timmy_dec_likes) { author_timmy_dec_posts.sum(&:likes) }
    let(:author_timmy_jan_likes) { author_timmy_jan_posts.sum(&:likes) }
    let(:author_timmy_feb_likes) { author_timmy_feb_posts.sum(&:likes) }
    let(:author_timmy_mar_likes) { author_timmy_mar_posts.sum(&:likes) }
    let(:author_timmy_apr_likes) { author_timmy_apr_posts.sum(&:likes) }

    it "should return raw_data" do
      expect(report.raw_data).to eq(
        [author_tammy.name, jan, "count"] => author_tammy_jan_count,
        [author_tammy.name, jan, "likes"] => author_tammy_jan_likes,
        [author_tammy.name, mar, "count"] => author_tammy_mar_count,
        [author_tammy.name, mar, "likes"] => author_tammy_mar_likes,
        [author_timmy.name, jan, "count"] => author_timmy_jan_count,
        [author_timmy.name, jan, "likes"] => author_timmy_jan_likes,
        [author_timmy.name, feb, "count"] => author_timmy_feb_count,
        [author_timmy.name, feb, "likes"] => author_timmy_feb_likes,
        [author_timmy.name, mar, "count"] => author_timmy_mar_count,
        [author_timmy.name, mar, "likes"] => author_timmy_mar_likes,
        [author_timmy.name, apr, "count"] => author_timmy_apr_count,
        [author_timmy.name, apr, "likes"] => author_timmy_apr_likes,
      )
    end

    it "should return flat_data" do
      expect(report.flat_data).to eq(
        [author_tammy.name, jan, "count"] => author_tammy_jan_count,
        [author_tammy.name, jan, "likes"] => author_tammy_jan_likes,
        [author_tammy.name, feb, "count"] => author_tammy_feb_count,
        [author_tammy.name, feb, "likes"] => author_tammy_feb_likes,
        [author_tammy.name, mar, "count"] => author_tammy_mar_count,
        [author_tammy.name, mar, "likes"] => author_tammy_mar_likes,
        [author_tammy.name, apr, "count"] => author_tammy_apr_count,
        [author_tammy.name, apr, "likes"] => author_tammy_apr_likes,
        [author_timmy.name, jan, "count"] => author_timmy_jan_count,
        [author_timmy.name, jan, "likes"] => author_timmy_jan_likes,
        [author_timmy.name, feb, "count"] => author_timmy_feb_count,
        [author_timmy.name, feb, "likes"] => author_timmy_feb_likes,
        [author_timmy.name, mar, "count"] => author_timmy_mar_count,
        [author_timmy.name, mar, "likes"] => author_timmy_mar_likes,
        [author_timmy.name, apr, "count"] => author_timmy_apr_count,
        [author_timmy.name, apr, "likes"] => author_timmy_apr_likes,
      )
    end

    it "should return nested_data" do
      expect(report.nested_data).to eq [
        { key: jan, values: [
          { key: author_tammy.name, values: [{ key: "count", value: author_tammy_jan_count }, { key: "likes", value: author_tammy_jan_likes }] },
          { key: author_timmy.name, values: [{ key: "count", value: author_timmy_jan_count }, { key: "likes", value: author_timmy_jan_likes }] },
        ] },
        { key: feb, values: [
          { key: author_tammy.name, values: [{ key: "count", value: author_tammy_feb_count }, { key: "likes", value: author_tammy_feb_likes }] },
          { key: author_timmy.name, values: [{ key: "count", value: author_timmy_feb_count }, { key: "likes", value: author_timmy_feb_likes }] },
        ] },
        { key: mar, values: [
          { key: author_tammy.name, values: [{ key: "count", value: author_tammy_mar_count }, { key: "likes", value: author_tammy_mar_likes }] },
          { key: author_timmy.name, values: [{ key: "count", value: author_timmy_mar_count }, { key: "likes", value: author_timmy_mar_likes }] },
        ] },
        { key: apr, values: [
          { key: author_tammy.name, values: [{ key: "count", value: author_tammy_apr_count }, { key: "likes", value: author_tammy_apr_likes }] },
          { key: author_timmy.name, values: [{ key: "count", value: author_timmy_apr_count }, { key: "likes", value: author_timmy_apr_likes }] },
        ] }
      ]
    end

    context "with calculators" do
      let(:parent_groupers) { %i(author) }
      let(:parent_dimensions) { { created_at: { only: { min: Date.new(year,1,1).to_s }}} }
      let(:aggregators) { %i(count likes) }
      let(:parent_report) { report_model.new({groupers: parent_groupers, dimensions: parent_dimensions, aggregators: aggregators}) }
      let(:calculators) { %i(likes_ratio) }

      let(:author_tammy_posts) { [post_tammy_jan01, post_tammy_jan12, post_tammy_mar08] }
      let(:author_tammy_posts_likes) { author_tammy_posts.sum(&:likes) }
      let(:author_timmy_posts) { [post_timmy_jan15, post_timmy_feb27, post_timmy_feb28, post_timmy_mar01, post_timmy_apr08] }
      let(:author_timmy_posts_likes) { author_timmy_posts.sum(&:likes) }

      let(:author_tammy_jan_likes_ratio) { author_tammy_jan_posts.none? || author_tammy_posts_likes.zero? ? nil : (author_tammy_jan_likes/author_tammy_posts_likes.to_f)*100 }
      let(:author_tammy_feb_likes_ratio) { author_tammy_feb_posts.none? || author_tammy_posts_likes.zero? ? nil : (author_tammy_feb_likes/author_tammy_posts_likes.to_f)*100 }
      let(:author_tammy_mar_likes_ratio) { author_tammy_mar_posts.none? || author_tammy_posts_likes.zero? ? nil : (author_tammy_mar_likes/author_tammy_posts_likes.to_f)*100 }
      let(:author_tammy_apr_likes_ratio) { author_tammy_apr_posts.none? || author_tammy_posts_likes.zero? ? nil : (author_tammy_apr_likes/author_tammy_posts_likes.to_f)*100 }

      let(:author_timmy_jan_likes_ratio) { author_timmy_jan_posts.none? || author_timmy_posts_likes.zero? ? nil : (author_timmy_jan_likes/author_timmy_posts_likes.to_f)*100 }
      let(:author_timmy_feb_likes_ratio) { author_timmy_feb_posts.none? || author_timmy_posts_likes.zero? ? nil : (author_timmy_feb_likes/author_timmy_posts_likes.to_f)*100 }
      let(:author_timmy_mar_likes_ratio) { author_timmy_mar_posts.none? || author_timmy_posts_likes.zero? ? nil : (author_timmy_mar_likes/author_timmy_posts_likes.to_f)*100 }
      let(:author_timmy_apr_likes_ratio) { author_timmy_apr_posts.none? || author_timmy_posts_likes.zero? ? nil : (author_timmy_apr_likes/author_timmy_posts_likes.to_f)*100 }

      it "should calculate" do
        expect(report.data).to eq [
          { key: jan, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_jan_count },
              { key: "likes", value: author_tammy_jan_likes },
              { key: "likes_ratio", value: author_tammy_jan_likes_ratio },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_jan_count },
              { key: "likes", value: author_timmy_jan_likes },
              { key: "likes_ratio", value: author_timmy_jan_likes_ratio },
            ] },
          ] },
          { key: feb, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_feb_count },
              { key: "likes", value: author_tammy_feb_likes },
              { key: "likes_ratio", value: author_tammy_feb_likes_ratio },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_feb_count },
              { key: "likes", value: author_timmy_feb_likes },
              { key: "likes_ratio", value: author_timmy_feb_likes_ratio },
            ] },
          ] },
          { key: mar, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_mar_count },
              { key: "likes", value: author_tammy_mar_likes },
              { key: "likes_ratio", value: author_tammy_mar_likes_ratio },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_mar_count },
              { key: "likes", value: author_timmy_mar_likes },
              { key: "likes_ratio", value: author_timmy_mar_likes_ratio },
            ] },
          ]},
          { key: apr, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_apr_count },
              { key: "likes", value: author_tammy_apr_likes },
              { key: "likes_ratio", value: author_tammy_apr_likes_ratio },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_apr_count },
              { key: "likes", value: author_timmy_apr_likes },
              { key: "likes_ratio", value: author_timmy_apr_likes_ratio },
            ] },
          ]},
        ]
      end
    end

    context "with trackers" do
      let(:aggregators) { %i(count likes) }
      let(:trackers) { %i(likes_delta) }

      let(:author_tammy_posts) { [post_tammy_jan01, post_tammy_jan12, post_tammy_mar08] }
      let(:author_tammy_posts_likes) { author_tammy_posts.sum(&:likes) }

      let(:author_timmy_posts) { [post_timmy_jan15, post_timmy_feb27, post_timmy_feb28, post_timmy_mar01, post_timmy_apr08] }
      let(:author_timmy_posts_likes) { author_timmy_posts.sum(&:likes) }

      let(:author_tammy_jan_likes_delta) { author_tammy_dec_likes.zero? || author_tammy_jan_likes.zero? ? nil : (author_tammy_jan_likes/author_tammy_dec_likes.to_f)*100 }
      let(:author_tammy_feb_likes_delta) { author_tammy_jan_likes.zero? || author_tammy_feb_likes.zero? ? nil : (author_tammy_feb_likes/author_tammy_jan_likes.to_f)*100 }
      let(:author_tammy_mar_likes_delta) { author_tammy_feb_likes.zero? || author_tammy_mar_likes.zero? ? nil : (author_tammy_mar_likes/author_tammy_feb_likes.to_f)*100 }
      let(:author_tammy_apr_likes_delta) { author_tammy_mar_likes.zero? || author_tammy_apr_likes.zero? ? nil : (author_tammy_apr_likes/author_tammy_mar_likes.to_f)*100 }

      let(:author_timmy_jan_likes_delta) { author_timmy_dec_likes.zero? || author_timmy_jan_likes.zero? ? nil : (author_timmy_jan_likes/author_timmy_dec_likes.to_f)*100 }
      let(:author_timmy_feb_likes_delta) { author_timmy_jan_likes.zero? || author_timmy_feb_likes.zero? ? nil : (author_timmy_feb_likes/author_timmy_jan_likes.to_f)*100 }
      let(:author_timmy_mar_likes_delta) { author_timmy_feb_likes.zero? || author_timmy_mar_likes.zero? ? nil : (author_timmy_mar_likes/author_timmy_feb_likes.to_f)*100 }
      let(:author_timmy_apr_likes_delta) { author_timmy_mar_likes.zero? || author_timmy_apr_likes.zero? ? nil : (author_timmy_apr_likes/author_timmy_mar_likes.to_f)*100 }

      it "should calculate" do
        expect(report.data).to eq [
          { key: jan, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_jan_count },
              { key: "likes", value: author_tammy_jan_likes },
              { key: "likes_delta", value: author_tammy_jan_likes_delta },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_jan_count },
              { key: "likes", value: author_timmy_jan_likes },
              { key: "likes_delta", value: author_timmy_jan_likes_delta },
            ] },
          ] },
          { key: feb, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_feb_count },
              { key: "likes", value: author_tammy_feb_likes },
              { key: "likes_delta", value: author_tammy_feb_likes_delta },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_feb_count },
              { key: "likes", value: author_timmy_feb_likes },
              { key: "likes_delta", value: author_timmy_feb_likes_delta },
            ] },
          ] },
          { key: mar, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_mar_count },
              { key: "likes", value: author_tammy_mar_likes },
              { key: "likes_delta", value: author_tammy_mar_likes_delta },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_mar_count },
              { key: "likes", value: author_timmy_mar_likes },
              { key: "likes_delta", value: author_timmy_mar_likes_delta },
            ] },
          ]},
          { key: apr, values: [
            { key: author_tammy.name, values: [
              { key: "count", value: author_tammy_apr_count },
              { key: "likes", value: author_tammy_apr_likes },
              { key: "likes_delta", value: author_tammy_apr_likes_delta },
            ] },
            { key: author_timmy.name, values: [
              { key: "count", value: author_timmy_apr_count },
              { key: "likes", value: author_timmy_apr_likes },
              { key: "likes_delta", value: author_timmy_apr_likes_delta },
            ] },
          ]},
        ]
      end
    end
  end

  describe "#dimensions" do
    it "is a curried hash" do
      expect(report_model.dimensions.keys).to include(:likes, :author, :created_at)
      expect(report.dimensions.keys).to include(:likes, :author, :created_at)
      expect(report.dimensions[:likes]).to be_a ActiveReporter::Dimension::Number
      expect(report.dimensions[:author]).to be_a ActiveReporter::Dimension::Category
      expect(report.dimensions[:created_at]).to be_a ActiveReporter::Dimension::Time
    end
  end

  describe "#calculators" do
    let(:parent_groupers) { %i(author) }
    let(:aggregators) { %i(count likes) }
    let(:parent_report) { report_model.new({groupers: parent_groupers, aggregators: aggregators}) }
    let(:calculators) { %i(likes_ratio) }

    it "should return configured calculators" do
      expect(report.calculators).to include(:likes_ratio)
    end
  end

  describe "#trackers" do
    let(:parent_groupers) { %i(author) }
    let(:aggregators) { %i(count likes) }
    let(:parent_report) { report_model.new({groupers: parent_groupers, aggregators: aggregators}) }
    let(:trackers) { %i(likes_delta) }

    it "should return configured trackers" do
      expect(report.trackers).to include(:likes_delta)
    end
  end

  describe "#params" do
    let(:author_phil) { create(:author, name: "Phil") }
    let(:author_phyllis) { create(:author, name: "Phyllis") }
    let(:date) { Date.new(year,1,1) }
    let(:author_phil_post1) { create(:post, author: author_phil, created_at: date) }
    let(:author_phil_post2) { create(:post, author: author_phil, created_at: date) }
    let(:author_phyllis_post1) { create(:post, author: author_phyllis, created_at: date) }
    let(:author_phyllis_post2) { create(:post, author: author_phyllis, created_at: date) }

    let(:all_posts) { [author_phil_post1, author_phil_post2, author_phyllis_post1, author_phyllis_post2] }
    let(:author_phil_posts) { [author_phil_post1, author_phil_post2] }
    let(:author_phyllis_posts) { [author_phyllis_post1, author_phyllis_post2] }

    context "where author dimension only allows empty string" do
      let(:report) { report_model.new(dimensions: { author: { only: "" }}) }

      it "strips empty string but preserves nil by default" do
        expect(report.params).to be_blank
        expect(report.dimensions[:author].filter_values).to be_blank
        expect(report.records).to contain_exactly(*all_posts)
      end
    end

    context "where author dimension only allows array of empty string" do
      let(:report) { report_model.new(dimensions: { author: { only: [""] }}) }

      it "strips empty string but preserves nil by default" do
        expect(report.params).to be_blank
        expect(report.dimensions[:author].filter_values).to be_blank
        expect(report.records).to contain_exactly(*all_posts)
      end
    end

    context "where author dimension only allows empty string or Phil" do
      let(:report) { report_model.new(dimensions: { author: { only: ["", author_phil.name] }}) }

      it "strips empty string but preserves nil by default" do
        expect(report.params).to be_present
        expect(report.dimensions[:author].filter_values).to contain_exactly(author_phil.name)
        expect(report.records).to contain_exactly(*author_phil_posts)
      end
    end

    context "where author dimension strips blank values and only allows empty string" do
      let(:report) { report_model.new(strip_blanks: false, dimensions: { author: { only: "" }}) }

      it "strips empty string but preserves nil by default" do
        expect(report.params).to be_present
        expect(report.dimensions[:author].filter_values).to eq([""])
        expect(report.records).to be_empty
      end
    end

    context "where author dimension only allows nil" do
      let(:report) { report_model.new(dimensions: { author: { only: nil }}) }

      it "strips empty string but preserves nil by default" do
        expect(report.params).to be_present
        expect(report.dimensions[:author].filter_values).to eq [nil]
        expect(report.records).to be_empty
      end
    end
  end

  describe "#parent_report" do
    let(:groupers) { %i(author created_at) }
    let(:aggregators) { %i(count likes) }
    let(:dimensions) { { created_at: { bin_width: { months: 1 }}} }
    let(:parent_report) { report_model.new({ groupers: %i(author), aggregators: aggregators }) }

    it "should return passed parent report" do
      expect(report.parent_report).to be_a report_model
    end
  end

  describe "#aggregators" do
    it "is a curried hash" do
      expect(report_model.aggregators.keys).to eq [:count, :likes]
      expect(report.aggregators.keys).to eq [:count, :likes]
      expect(report.aggregators[:count]).to be_a ActiveReporter::Aggregator::Count
      expect(report.aggregators[:likes]).to be_a ActiveReporter::Aggregator::Sum
    end
  end

  describe "#groupers" do
    it "defaults to the first" do
      expect(report.groupers).to eq [report.dimensions[:likes]]
    end

    context "with created_at group" do
      let(:groupers) { "created_at" }

      it "can be set" do
        expect(report.groupers).to eq [report.dimensions[:created_at]]
      end
    end

    context "with created_at and author groups" do
      let(:groupers) { %w(created_at author) }

      it "can be set" do
        expect(report.groupers).to eq [report.dimensions[:created_at], report.dimensions[:author]]
      end
    end

    context "with invalid group" do
      let(:groupers) { %w(chickens) }

      it "should raise an exception" do
        expect { report }.to raise_error(ActiveReporter::InvalidParamsError)
      end
    end

    context "on a report class with no dimensions declared" do
      let(:report_model) do
        Class.new(ActiveReporter::Report) do
          report_on :Post
          count_aggregator :count
        end
      end

      it "should have at least one defined" do
        expect { report }.to raise_error Regexp.new("does not declare any dimensions")
      end
    end
  end

  describe "#aggregators" do
    context "where the report aggregators are set" do
      let(:aggregators) { "likes" }

      it "returns the set aggregators" do
        expect(report.aggregators.values).to contain_exactly report.aggregators[:likes]
      end
    end

    context "where the report aggregators include an invalid value" do
      let(:aggregators) { "chicken" }

      it "should raise an exception" do
        expect { report }.to raise_error(ActiveReporter::InvalidParamsError)
      end
    end

    context "on a report class with no dimensions declared" do
      let(:report_model) do
        Class.new(ActiveReporter::Report) do
          report_on :Post
          time_dimension :created_at
        end
      end

      it "should have at least one defined" do
        expect { report }.to raise_error Regexp.new("does not declare any aggregators or trackers")
      end
    end
  end

  describe "#total_data" do
    let(:groupers) { %w(author created_at) }
    let(:aggregators) { %i(count likes) }
    let(:dimensions) { { likes: { bin_width: 1 }, created_at: { bin_width: { months: 1 }}} }

    let(:author_timmy) { create(:author, name: "Timmy") }
    let(:author_tammy) { create(:author, name: "Tammy") }
    let!(:author_timmy_jan01_post) { create(:post, author: author_timmy, created_at: Date.new(year,1,1), likes: 1) }
    let!(:author_timmy_jan12_post) { create(:post, author: author_timmy, created_at: Date.new(year,1,12), likes: 2) }
    let!(:author_tammy_jan15_post) { create(:post, author: author_tammy, created_at: Date.new(year,1,15), likes: 3) }
    let!(:author_tammy_mar01_post) { create(:post, author: author_tammy, created_at: Date.new(year,3,1), likes: 4) }
    let!(:author_tammy_mar15_post) { create(:post, author: author_tammy, created_at: Date.new(year,3,15), likes: 2) }

    let(:all_posts) { [author_timmy_jan01_post, author_timmy_jan12_post, author_tammy_jan15_post, author_tammy_mar01_post, author_tammy_mar15_post] }
    let(:all_posts_count) { all_posts.count }
    let(:all_posts_likes) { all_posts.sum(&:likes) }

    it "should return total_data" do
      expect(report.total_data).to eq({
        ["totals", "count"] => all_posts_count,
        ["totals", "likes"] => all_posts_likes,
      })
    end

    context "with calculators" do
      let(:parent_report_model) do
        Class.new(ActiveReporter::Report) do
          report_on :Post
          count_aggregator :count
          sum_aggregator :likes
          max_aggregator :max_likes, attribute: :likes
          number_dimension :likes
          category_dimension :author, model: :author, attribute: :name, relation: ->(r) { r.joins(:author) }
          time_dimension :created_at
        end
      end

      let(:dimensions) { { likes: { bin_width: 1 }, created_at: { bin_width: { months: 1 }}, author: { only: author_tammy.name }} }
      let(:parent_dimensions) { { likes: { bin_width: 1 }, created_at: { bin_width: { months: 1 }}} }
      let(:parent_groupers) { %i(author) }
      let(:calculators) { %i(likes_ratio) }
      let(:trackers) { %i(likes_delta) }
      let(:parent_report) { parent_report_model.new({groupers: parent_groupers, aggregators: aggregators, dimensions: parent_dimensions}) }

      let(:author_tammy_posts) { [author_tammy_jan15_post, author_tammy_mar01_post, author_tammy_mar15_post] }
      let(:author_tammy_posts_count) { author_tammy_posts.count }
      let(:author_tammy_posts_likes) { author_tammy_posts.sum(&:likes) }
      let(:author_tammy_posts_likes_ratio) { all_posts_likes.zero? ? nil : (author_tammy_posts_likes/all_posts_likes.to_f)*100 }

      it "should calculate" do
        expect(report.total_data).to eq({
          ["totals", "count"] => author_tammy_posts_count,
          ["totals", "likes"] => author_tammy_posts_likes,
          ["totals", "likes_ratio"] => author_tammy_posts_likes_ratio
        })
      end
    end
  end
end
