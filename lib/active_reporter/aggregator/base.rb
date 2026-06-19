# frozen_string_literal: true

module ActiveReporter
  module Aggregator
    class Base
      attr_reader :name, :report, :opts

      def initialize(name, report, opts={})
        @name = name
        @report = report
        @opts = opts
        validate_params!
      end

      def sql_value_name
        "_report_aggregator_#{name}"
      end

      def default_value
        opts.fetch(:default_value, nil)
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
        opts.fetch(:relation, ->(r) { r })
      end

      def model
        opts.fetch(:model, report.report_model)
      end

      def attribute
        opts.fetch(:attribute, name)
      end

      def table_name
        @table_name ||= opts[:table_name] || model.try(:table_name) || model.to_s.safe_constantize.try(:table_name) || report.table_name
      end

      def column
        opts.fetch(:column, attribute)
      end

      def expression
        "#{table_name}.#{column}"
      end

      def enum?
        Hash(model&.defined_enums).include?(attribute.to_s)
      end
    end
  end
end
