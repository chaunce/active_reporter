# frozen_string_literal: true

require 'active_reporter/aggregator/base'

module ActiveReporter
  module Calculator
    class Base < ActiveReporter::Aggregator::Base
      def aggregator
        options[:aggregator] || name
      end

      def parent_aggregator
        options[:parent_aggregator] || aggregator
      end

      def totals?
        !!options[:totals]
      end
    end
  end
end
