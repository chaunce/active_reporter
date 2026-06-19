require "spec_helper"

describe ActiveReporter::Dimension::Boolean do
  def featured_dimension(report)
    described_class.new(:featured, report, model: :post, attribute: :featured)
  end

  describe "#filter_values" do
    it "casts assorted truthy/falsey values to booleans and preserves nil" do
      report = OpenStruct.new(params: { dimensions: { featured: { only: ["true", "false", "1", "0", nil] } } })

      expect(featured_dimension(report).filter_values).to eq [true, false, nil]
    end
  end

  describe "#filter" do
    let!(:featured_post) { create(:post, featured: true) }
    let!(:plain_post) { create(:post, featured: false) }

    def filter_by(values)
      report = OpenStruct.new(table_name: "posts", params: { dimensions: { featured: { only: values } } })
      dimension = featured_dimension(report)
      dimension.filter(dimension.relate(Post))
    end

    it "filters by the casted boolean value" do
      expect(filter_by(["true"])).to contain_exactly(featured_post)
      expect(filter_by([false])).to contain_exactly(plain_post)
    end
  end

  describe "#group" do
    let!(:featured_post) { create(:post, featured: true) }
    let!(:plain_one) { create(:post, featured: false) }
    let!(:plain_two) { create(:post, featured: false) }

    it "groups by the boolean value, normalized to true/false on every adapter" do
      report = OpenStruct.new(table_name: "posts", params: {})
      dimension = featured_dimension(report)

      results = dimension.group(dimension.relate(Post)).select("COUNT(*) AS count").map do |row|
        [dimension.extract_sql_value(row), row.attributes["count"]]
      end

      expect(results).to contain_exactly([false, 2], [true, 1])
    end
  end
end
