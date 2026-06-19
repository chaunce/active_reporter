require "spec_helper"

describe ActiveReporter::Dimension::Base do
  def new_dimension(dimension_params = {}, report_params = {}, opts = {})
    report_params[:dimensions] = { foo: dimension_params }
    ActiveReporter::Dimension::Base.new(
      :foo,
      OpenStruct.new(params: report_params),
      opts
    )
  end

  describe "#filter_values" do
    it "accepts one" do
      dimension = new_dimension(only: "bar")
      expect(dimension.filter_values).to eq %w(bar)
    end

    it "accepts many" do
      dimension = new_dimension(only: %w(bar baz))
      expect(dimension.filter_values).to eq %w(bar baz)
    end

    it "determines #filtering?" do
      dimension = new_dimension(only: %w(bar baz))
      expect(dimension).to be_filtering

      dimension = new_dimension
      expect(dimension).not_to be_filtering
    end
  end

  describe "#sort_order" do
    it "can be desc/asc, falls back to root, defaults to asc" do
      dimension = new_dimension
      expect(dimension.sort_order).to eq "ASC"

      dimension = new_dimension(sort_desc: true)
      expect(dimension.sort_order).to eq "DESC"

      dimension = new_dimension(sort_desc: false)
      expect(dimension.sort_order).to eq "ASC"

      dimension = new_dimension({}, sort_desc: true)
      expect(dimension.sort_order).to eq "DESC"

      dimension = new_dimension({}, sort_desc: false)
      expect(dimension.sort_order).to eq "ASC"
    end
  end

  describe "#null_order" do
    it "can be first/last, falls back to root, defaults to first (only if postgres)" do
      if ActiveReporter.database_type == :postgres
        dimension = new_dimension
        expect(dimension.null_order).to eq "NULLS FIRST"

        dimension = new_dimension(nulls_last: true)
        expect(dimension.null_order).to eq "NULLS LAST"

        dimension = new_dimension(nulls_last: false)
        expect(dimension.null_order).to eq "NULLS FIRST"

        dimension = new_dimension({}, nulls_last: true)
        expect(dimension.null_order).to eq "NULLS LAST"

        dimension = new_dimension({}, nulls_last: false)
        expect(dimension.null_order).to eq "NULLS FIRST"
      else
        dimension = new_dimension
        expect(dimension.null_order).to be_blank
      end
    end
  end

  describe "#relate" do
    it "defaults to the identity function" do
      dimension = new_dimension
      expect(dimension.relate(5)).to eq 5
    end

    it "can be overridden, e.g. for joins" do
      dimension = new_dimension({}, {}, relation: ->(r) { r + 5 })
      expect(dimension.relate(5)).to eq 10
    end
  end

  describe "#expression" do
    it "defaults to treating name as a column of the report klass table" do
      dimension = ActiveReporter::Dimension::Base.new(
        :bar,
        OpenStruct.new(table_name: "foo")
      )
      expect(dimension.expression).to eq("foo.bar")
    end

    it "can be overridden" do
      dimension = new_dimension({}, {}, table_name: :baz, attribute: :bat)
      expect(dimension.expression).to eq "baz.bat"
    end
  end

  describe "abstract interface" do
    it "raises NotImplementedError for #filter, #group, and #group_values" do
      dimension = new_dimension

      expect { dimension.filter(nil) }.to raise_error(NotImplementedError)
      expect { dimension.group(nil) }.to raise_error(NotImplementedError)
      expect { dimension.group_values }.to raise_error(NotImplementedError)
    end
  end

  describe "#enum?" do
    it "is false when the attribute is not a model enum" do
      expect(new_dimension.send(:enum?)).to be false
    end

    it "is true when the attribute is a model enum" do
      dimension = new_dimension({}, {}, model: :post, attribute: :status)
      expect(dimension.send(:enum?)).to be true
    end
  end
end
