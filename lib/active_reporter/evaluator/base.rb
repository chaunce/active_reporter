module ActiveReporter
  module Evaluator
    class Base
      attr_reader :name, :report, :opts

      def initialize(name, report, opts={})
        @name = name
        @report = report
        @opts = opts
      end

      def default_value
        opts.fetch(:default_value, nil)
      end
    end
  end
end
