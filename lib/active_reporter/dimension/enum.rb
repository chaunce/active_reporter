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

      def filter(relation)
        values = if Rails.gem_version >= Gem::Version.new("7")
          filter_values.map { |value| enum_values[value] }.uniq
        else
          filter_values
        end
        query = case values
        when [] then "1=0"
        when [nil] then "#{expression} IS NULL"
        else
          in_values = "#{expression} IN (?)"
          values.include?(nil) ? "#{expression} IS NULL OR #{in_values}" : in_values
        end
        relation.where(query, values.compact)
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
        Hash(model&.defined_enums).include?(attribute.to_s)
      end
    end
  end
end
