require 'repor/dimension/category'

module Repor
  module Dimension
    class Enum < Category
      def group_values
        return filter_values if filtering?
          
        i = report.groupers.index(self)
        enum_values.invert.slice(report.raw_data.keys.map { |x| x[i] }.uniq).values
      end

      def all_values
        enum_values.keys
      end

      private

      def enum_values
        model.defined_enums[attribute.to_s]
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