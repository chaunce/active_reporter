# frozen_string_literal: true

module ActiveReporter
  module Aggregator
    class Ratio < ActiveReporter::Aggregator::Base
      attr_reader :numerator, :denominator

      def function
        "(#{numerator}/NULLIF(#{denominator},0)::FLOAT)"
      end

      private

      def numerator
        raise "Ratio aggregator must specify a numerator column" unless options.include?(:numerator)
        @numerator = report.aggregators[options[:numerator].to_sym].try(:function) || "#{report.table_name}.#{options[:numerator]}"
      end

      def denominator
        raise "Ratio aggregator must specify a denominator column" unless options.include?(:denominator)
        @denominator = report.aggregators[options[:denominator].to_sym].try(:function) || "#{report.table_name}.#{options[:denominator]}"
      end
    end
  end
end
