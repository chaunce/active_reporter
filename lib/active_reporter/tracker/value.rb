module ActiveReporter
  module Tracker
    class Value < ActiveReporter::Tracker::Base
      def track(_, prior_row)
        prior_row[aggregator] if prior_row.nil?
      end
    end
  end
end
