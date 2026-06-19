# frozen_string_literal: true

require "active_reporter/aggregator/base"

module ActiveReporter
  module Tracker
    class Base < ActiveReporter::Aggregator::Base
      def aggregator
        options[:aggregator] || name
      end

      def prior_aggregator
        options[:prior_aggregator] || aggregator
      end
    end
  end
end
