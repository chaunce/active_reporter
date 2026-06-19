require "spec_helper"

describe ActiveReporter::Dimension::Category do
  def author_dimension(report)
    described_class.new(:author, report, model: :authors, attribute: :name, relation: ->(r) { r.joins(
      "LEFT OUTER JOIN authors ON authors.id = posts.author_id") })
  end

  describe "#filter" do
    let(:author_alice) { create(:author, name: "Alice") }
    let(:author_bob) { create(:author, name: "Bob") }

    let!(:post_by_alice) { create(:post, author: author_alice) }
    let!(:post_by_bob) { create(:post, author: author_bob) }
    let!(:post_without_author) { create(:post, author: nil) }

    def filter_by(author_values)
      report = OpenStruct.new(
        table_name: "posts",
        params: { dimensions: { author: { only: author_values } } }
      )
      dimension = author_dimension(report)
      dimension.filter(dimension.relate(Post))
    end

    it "filters to rows matching at least one value" do
      expect(filter_by([author_alice.name])).to eq [post_by_alice]
      expect(filter_by([nil])).to eq [post_without_author]
      expect(filter_by([author_alice.name, nil])).to eq [post_by_alice, post_without_author]
      expect(filter_by([author_alice.name, author_bob.name])).to eq [post_by_alice, post_by_bob]
      expect(filter_by([])).to eq []
    end
  end

  describe "#group" do
    let(:author_alice) { create(:author, name: "Alice") }
    let(:author_bob) { create(:author, name: "Bob") }

    let!(:post_alice_1) { create(:post, author: author_alice) }
    let!(:post_alice_2) { create(:post, author: author_alice) }
    let!(:post_without_author) { create(:post, author: nil) }
    let!(:post_bob_1) { create(:post, author: author_bob) }
    let!(:post_bob_2) { create(:post, author: author_bob) }
    let!(:post_bob_3) { create(:post, author: author_bob) }

    it "groups the relation by the exact value of the SQL expression" do
      report = OpenStruct.new(table_name: "posts", params: {})
      dimension = author_dimension(report)

      results = dimension.group(dimension.relate(Post)).select("COUNT(*) AS count").map do |r|
        r.attributes.values_at(dimension.send(:sql_value_name), "count")
      end

      expect(results).to eq [[nil, 1], [author_alice.name, 2], [author_bob.name, 3]]
    end
  end

  describe "#group_values" do
    it "echoes filter_values if filtering" do
      dimension = author_dimension(OpenStruct.new(params: {
        dimensions: { author: { only: ["foo", "bar"] } }
      }))
      expect(dimension.group_values).to eq %w(foo bar)
    end
  end
end
