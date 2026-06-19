require "spec_helper"

describe ActiveReporter::Dimension::Bin::Set do
  describe ".from_hash" do
    it "builds a bin from a hash or nil" do
      bin = described_class.from_hash(min: 1, max: 2)
      expect(bin.min).to eq 1
      expect(bin.max).to eq 2

      bin = described_class.from_hash(nil)
      expect(bin.min).to eq nil
      expect(bin.max).to eq nil
    end
  end

  describe ".from_hash" do
    it "returns nil for a non-hash, non-nil source" do
      expect(described_class.from_hash("not a hash")).to be_nil
    end
  end

  describe ".from_sql" do
    it "builds a bin from a bin text string" do
      bin = described_class.from_sql("1,2")
      expect(bin.min).to eq "1"
      expect(bin.max).to eq "2"

      bin = described_class.from_sql("1,")
      expect(bin.min).to eq "1"
      expect(bin.max).to eq nil

      bin = described_class.from_sql(",2")
      expect(bin.min).to eq nil
      expect(bin.max).to eq "2"

      bin = described_class.from_sql(",")
      expect(bin.min).to eq nil
      expect(bin.max).to eq nil
    end

    it "raises on an unrecognized bin format" do
      expect { described_class.from_sql("not-a-bin") }.to raise_error(/Unexpected SQL bin format/)
    end
  end

  describe "#as_json" do
    it "includes only the present edges" do
      expect(described_class.new(1, nil).as_json).to eq(min: 1)
      expect(described_class.new(nil, 2).as_json).to eq(max: 2)
    end
  end

  describe "hash-like access" do
    let(:bin) { described_class.new(1, 2) }

    it "responds to has_key?/key? for min and max" do
      expect(bin.has_key?("min")).to be true
      expect(bin.key?(:max)).to be true
      expect(bin.has_key?(:other)).to be false
    end

    it "supports values_at" do
      expect(bin.values_at(:min, :max)).to eq [1, 2]
    end
  end

  describe "#inspect" do
    it "shows the min and max" do
      expect(described_class.new(1, 2).inspect).to eq "<Bin @min=1 @max=2>"
    end
  end

  describe "#cast_bin_text" do
    it "quotes the bin text without casting on mysql" do
      allow(ActiveReporter).to receive(:database_type).and_return(:mysql)
      expect(described_class.new(1, 2).cast_bin_text).to eq described_class.new(1, 2).send(:quote, "1,2")
    end
  end

  describe "#contains_sql" do
    it "returns SQL checking if expr is in the bin" do
      bin = described_class.new(1, 2)
      expect(bin.contains_sql("foo")).to eq "(foo >= 1 AND foo < 2)"

      bin = described_class.new(1, nil)
      expect(bin.contains_sql("foo")).to eq "foo >= 1"

      bin = described_class.new(nil, 2)
      expect(bin.contains_sql("foo")).to eq "foo < 2"

      bin = described_class.new(nil, nil)
      expect(bin.contains_sql("foo")).to eq "foo IS NULL"
    end
  end

  describe "#to_json" do
    it "reexpresses the bin as a hash" do
      bin = described_class.new(1, 2)
      json = { a: bin }.to_json
      expect(JSON.parse(json)).to eq("a" => { "min" => 1, "max" => 2 })
    end
  end

  describe "hashing" do
    it "works with hashes" do
      bin1 = described_class.new(1, 2)
      bin2 = described_class.new(1, 2)
      bin3 = { min: 1, max: 2 }

      h = { bin3 => "foo" }
      expect(h[bin1]).to eq "foo"
      expect(h[bin2]).to eq "foo"
      expect(h[bin3]).to eq "foo"
    end

    it "works with nil" do
      bin1 = described_class.new(nil, nil)
      bin2 = described_class.new(nil, nil)
      bin3 = nil

      h = { bin3 => "foo" }
      expect(h[bin1]).to eq "foo"
      expect(h[bin2]).to eq "foo"
      expect(h[bin3]).to eq "foo"
    end
  end
end
