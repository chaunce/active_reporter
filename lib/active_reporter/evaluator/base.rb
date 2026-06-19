# frozen_string_literal: true

module ActiveReporter
  module Evaluator
    class Base
      attr_reader :name, :report, :options

      def initialize(name, report, options={})
        @name = name
        @report = report
        @options = options
      end

      def default_value
        options.fetch(:default_value, nil)
      end
    end
  end
end
