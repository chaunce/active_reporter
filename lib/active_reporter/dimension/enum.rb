require "active_reporter/dimension/category"

module ActiveReporter
  module Dimension
    class Enum < Category
      def group_values
        return filter_values if filtering?

        all_values & report_values
      end

      def all_values
        enum_values.keys.tap { |values| values.unshift(nil) unless values.include?(nil) }.uniq
      end

      private

      def enum_values
        model.defined_enums[attribute.to_s] || {}
      end

      def report_values
        return [] if report.raw_data.nil?

        i = report.groupers.index(self)
        report.raw_data.keys.map { |x| x[i] }.uniq
      end

      def sanitize_sql_value(value)
        enum_values.invert[value]
      end

      def enum?
        true # Hash(model&.defined_enums).include?(attribute.to_s)
      end
    end
  end
end
