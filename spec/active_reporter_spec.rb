# frozen_string_literal: true

require "spec_helper"

describe ActiveReporter do
  describe ".database_type" do
    # database_type memoizes its result and is derived from the connection, so
    # save/restore the real values and drive each branch via a stubbed adapter.
    around do |example|
      saved_type = ActiveReporter.instance_variable_get(:@database_type)
      saved_adapter = ActiveReporter.instance_variable_get(:@database_adapter)
      example.run
      ActiveReporter.instance_variable_set(:@database_type, saved_type)
      ActiveReporter.instance_variable_set(:@database_adapter, saved_adapter)
    end

    def database_type_for(adapter)
      ActiveReporter.instance_variable_set(:@database_type, nil)
      allow(ActiveReporter).to receive(:database_adapter).and_return(adapter)
      ActiveReporter.database_type
    end

    it "maps postgres adapters" do
      expect(database_type_for("postgresql")).to eq :postgres
    end

    it "maps mysql adapters" do
      expect(database_type_for("mysql2")).to eq :mysql
    end

    it "maps sqlite adapters" do
      expect(database_type_for("sqlite3")).to eq :sqlite
    end

    it "raises for unsupported adapters" do
      ActiveReporter.instance_variable_set(:@database_type, nil)
      allow(ActiveReporter).to receive(:database_adapter).and_return("oracle")

      expect { ActiveReporter.database_type }.to raise_error(/unsupported database/)
    end
  end

  describe ".numeric?" do
    it "is true for numbers" do
      expect(ActiveReporter.numeric?(5)).to be true
      expect(ActiveReporter.numeric?(5.2)).to be true
    end

    it "is true for numeric strings" do
      expect(ActiveReporter.numeric?("5")).to be_truthy
      expect(ActiveReporter.numeric?("5.2")).to be_truthy
    end

    it "is false for non-numeric strings and nil" do
      expect(ActiveReporter.numeric?("abc")).to be_falsey
      expect(ActiveReporter.numeric?(nil)).to be_falsey
    end
  end
end
