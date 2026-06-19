# frozen_string_literal: true

module ActiveReporter
  module Aggregator
    class Base
      attr_reader :name, :report, :options

      def initialize(name, report, options = {})
        @name = name
        @report = report
        @options = options
        validate_params!
      end

      def sql_value_name
        "_report_aggregator_#{name}"
      end

      def default_value
        options.fetch(:default_value, nil)
      end

      def aggregate(groups)
        relate(groups).select("#{function} AS #{sql_value_name}")
      end

      private

      # Validation hook run on initialize; aggregator subclasses may override and
      # `super` into it to validate their params.
      def validate_params!
      end

      def relate(groups)
        relation.call(groups)
      end

      def relation
        options.fetch(:relation, ->(r) { r })
      end

      def model
        options.fetch(:model, report.report_model)
      end

      def attribute
        options.fetch(:attribute, name)
      end

      def table_name
        @table_name ||= options[:table_name] || model.try(:table_name) || model.to_s.safe_constantize.try(:table_name) || report.table_name
      end

      def column
        options.fetch(:column, attribute)
      end

      def expression
        options[:expression] || "#{table_name}.#{column}"
      end

      def enum?
        Hash(model&.defined_enums).include?(attribute.to_s)
      end
    end
  end
end
