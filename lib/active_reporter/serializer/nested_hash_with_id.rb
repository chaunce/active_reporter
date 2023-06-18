module ActiveReporter
  module Serializer
    class NestedHashWithId < Base
      ID_DELIMITER = "✦".freeze

      def table
        report.hashed_data.collect { |row| row.map { |k,v| [k, (v.respond_to?(:min) ? v.min : v).to_s] }.to_h }.collect do |row|
          row_with_id = row.merge(_id: row.slice(*report.grouper_names).values.join(key_delimiter))
          report.grouper_names.reverse.inject(row_with_id.slice(*report.all_aggregators.keys.prepend(:_id))) do |nested_row_data, group|
            { row_with_id[group] => nested_row_data }
          end
        end.reduce({}, :deep_merge)
      end

      private

      def key_delimiter
        @key_delimiter ||= @options[:id_delimiter] || ID_DELIMITER
      end
    end
  end
end
