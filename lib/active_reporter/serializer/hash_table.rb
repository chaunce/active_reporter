module ActiveReporter
  module Serializer
    class HashTable < Base
      def table
        fields = (report.grouper_names + report.all_aggregators.keys)
        titles = report.groupers.map(&method(:human_dimension_label)) + report.all_aggregators.collect { |k, v| human_aggregator_label({ k => v }) }

        [fields.zip(titles).to_h] + report.hashed_data.collect { |row| row.map { |k,v| [k, (v.respond_to?(:min) ? v.min : v).to_s] }.to_h}
      end
    end
  end
end
