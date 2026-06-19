# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter::Dimension::Time do
  def new_dimension(dimension_params = {}, report_params = {}, opts = {})
    report_params[:dimensions] = { foo: dimension_params }
    ActiveReporter::Dimension::Time.new(
      :foo,
      OpenStruct.new(params: report_params),
      opts
    )
  end

  def expect_error(&block)
    expect { yield }.to raise_error(ActiveReporter::InvalidParamsError)
  end

  describe "param validation" do
    it "yells unless :bin_width is a duration hash" do
      expect_error { new_dimension(bin_width: "") }
      expect_error { new_dimension(bin_width: 5) }
      expect_error { new_dimension(bin_width: { seconds: "hey" }) }
      expect_error { new_dimension(bin_width: { seconds: 1, chickens: 0 }) }
      new_dimension(bin_width: { seconds: 1, minutes: 2 })
      new_dimension(bin_width: { weeks: 12, years: 7 })
    end

    it "yells unless :bins and :only values are times" do
      expect_error { new_dimension(bins: { min: "hey" }) }
      expect_error { new_dimension(only: { min: "hey" }) }
      expect_error { new_dimension(only: [{ min: "2015-01-01", max: "2015-01-10" }, { min: "chicken" }]) }
      new_dimension(bins: { min: "2015-01-01", max: "2015-01-10" })
      new_dimension(only: { min: "2015-01-01", max: "2015-01-10" })
      new_dimension(only: [nil, { min: "2015-01-01", max: "2015-01-10" }, { max: "2015-02-10" }])
    end
  end

  describe "#bin_width" do
    it "can translate a duration hash into an ActiveSupport::Duration" do
      dimension = new_dimension(bin_width: { seconds: 10, minutes: 1 })
      expect(dimension.bin_width).to eq 70.seconds
      dimension = new_dimension(bin_width: { days: 8, weeks: 1 })
      expect(dimension.bin_width).to eq 15.days
    end

    it "can divide the domain into :bin_count bins" do
      dimension = new_dimension(bin_count: 10, only: [{ min: "2015-01-01" }, { max: "2015-01-11" }])
      allow(dimension).to receive(:data_contains_nil?).and_return(false)
      expect(dimension.bin_width).to eq 1.day
      expect(dimension.group_values.map(&:min).map(&:day)).to eq (1..10).to_a
    end

    it "defaults to a sensical, standard duration" do
      dimension = new_dimension(only: [{ min: "2015-01-01 00:00:00" }, { max: "2015-01-01 00:00:30" }])
      expect(dimension.bin_width).to eq 1.second
      dimension = new_dimension(only: [{ min: "2015-01-01 00:00:00" }, { max: "2015-01-01 01:00:00" }])
      expect(dimension.bin_width).to eq 1.minute
      dimension = new_dimension(only: [{ min: "2015-01-01" }, { max: "2015-01-02" }])
      expect(dimension.bin_width).to eq 1.hour
      dimension = new_dimension(only: [{ min: "2015-01-01" }, { max: "2015-01-11" }])
      expect(dimension.bin_width).to eq 1.day
      dimension = new_dimension(only: [{ min: "2015-01-01" }, { max: "2015-02-11" }])
      expect(dimension.bin_width).to eq 1.week
      dimension = new_dimension(only: [{ min: "2015-01-01" }, { max: "2016-01-01" }])
      expect(dimension.bin_width).to eq 1.month
      dimension = new_dimension(only: [{ min: "2015-01-01" }, { max: "2018-01-01" }])
      expect(dimension.bin_width).to eq 1.year
    end

    it "treats a bare unit string as a width of one" do
      expect(new_dimension(bin_width: "month").bin_width).to eq 1.month
      expect(new_dimension(bin_width: "week").bin_width).to eq 1.week
    end

    it "defaults to one day when the domain is zero" do
      expect(new_dimension(only: [{ min: "2015-01-01", max: "2015-01-01" }]).bin_width).to eq 1.day
    end
  end

  describe ActiveReporter::Dimension::Time::Set do
    let(:bin) { described_class.new("2015-01-01", "2015-02-01") }

    it "casts values per database adapter" do
      allow(ActiveReporter).to receive(:database_type).and_return(:sqlite)
      expect(bin.cast(bin.min)).to match(/\ADATETIME\(/)

      allow(ActiveReporter).to receive(:database_type).and_return(:mysql)
      expect(bin.cast(bin.min)).to match(/\ACAST\(.* AS DATETIME\)\z/)
    end
  end
end
