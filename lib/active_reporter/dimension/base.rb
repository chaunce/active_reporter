# frozen_string_literal: true

module ActiveReporter
  module Dimension
    class Base
      attr_reader :name, :report, :options

      def initialize(name, report, options={})
        @name = name
        @report = report
        @options = options
        validate_params!
      end

      def model
        @model ||= options[:model].to_s.classify.safe_constantize || options[:model] || report.report_model
      end

      def attribute
        options.fetch(:attribute, name)
      end

      def expression
        @expression ||= options.include?(:_alias) ? "'#{options[:_alias]}'" : "#{table_name}.#{column}"
      end

      # Do any joins/selects necessary to filter or group the relation.
      def relate(relation)
        options.fetch(:relation, ->(r) { r }).call(relation)
      end

      # Filter the relation based on any constraints in the params
      def filter(relation)
        raise NotImplementedError
      end

      # Group the relation by the expression -- ensure this is ordered, too.
      def group(relation)
        raise NotImplementedError
      end

      # Return an ordered array of all values that should appear in `Report#data`
      def group_values
        raise NotImplementedError
      end

      # Given a single (hashified) row of the SQL result, return the Ruby
      # object representing this dimension's value
      def extract_sql_value(row)
        sanitize_sql_value(row[sql_value_name])
      end

      def filter_values
        array_param(:only).uniq
      end

      # Return whether the report should filter by this dimension
      def filtering?
        filter_values.present?
      end

      def grouping?
        report.groupers.include?(self)
      end

      def order_expression
        sql_value_name
      end

      def order(relation)
        relation.order(Arel.sql("#{order_expression} #{sort_order} #{null_order}"))
      end

      def sort_desc?
        dimension_or_root_param(:sort_desc)
      end

      def sort_order
        sort_desc? ? "DESC" : "ASC"
      end

      def nulls_last?
        value = dimension_or_root_param(:nulls_last)
        value = !value if sort_desc?
        value
      end

      def null_order
        return unless ActiveReporter.database_type == :postgres
        nulls_last? ? "NULLS LAST" : "NULLS FIRST"
      end

      def params
        report.params.fetch(:dimensions, {})[name].presence || {}
      end

      private

      # Validation hook run on initialize; subclasses (Bin/Number/Time) override
      # this and `super` into it to validate their dimension params.
      def validate_params!
      end

      def invalid_param!(param_key, message)
        raise InvalidParamsError, "Invalid value for params[:dimensions][:#{name}][:#{param_key}]\n  :#{param_key} #{message}"
      end

      def table_name
        @table_name ||= options[:table_name] || model.try(:table_name) || model.to_s.safe_constantize.try(:table_name) || report.table_name
      end

      def column
        options.fetch(:column, attribute)
      end

      def sql_value_name
        "_active_reporter_dimension_#{name}"
      end

      def sanitize_sql_value(value)
        value
      end

      def dimension_or_root_param(key)
        params.fetch(key, report.params[key])
      end

      def array_param(key)
        return [] unless params.key?(key)
        return [nil] if params[key].nil?
        Array.wrap(params[key])
      end

      def enum?
        Hash(model&.defined_enums).include?(attribute.to_s)
      end
    end
  end
end
