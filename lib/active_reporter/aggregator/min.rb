# frozen_string_literal: true

module ActiveReporter
  module Aggregator
    class Min < ActiveReporter::Aggregator::Base
      def function
        "MIN(#{expression})"
      end
    end
  end
end
