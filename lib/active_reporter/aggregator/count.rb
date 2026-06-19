# frozen_string_literal: true

module ActiveReporter
  module Aggregator
    class Count < ActiveReporter::Aggregator::Base
      def function
        "COUNT(#{"DISTINCT" if distinct} #{expression})"
      end

      def default_value
        super || 0
      end

      private

      def distinct
        options.fetch(:distinct, true)
      end

      def column
        options.fetch(:column, :id)
      end
    end
  end
end
