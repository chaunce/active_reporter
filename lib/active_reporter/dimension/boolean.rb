module ActiveReporter
  module Dimension
    class Boolean < Category
      # Cast incoming filter values ("true"/"1"/etc.) to real booleans so they
      # match the column, preserving nil for IS NULL filtering.
      def filter_values
        super.map { |value| cast_boolean(value) }.uniq
      end

      # Group/raw values come back adapter-specific (1/0 on SQLite and MySQL,
      # true/false on PostgreSQL); normalize them to booleans (or nil).
      def sanitize_sql_value(value)
        cast_boolean(value)
      end

      private

      def cast_boolean(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
