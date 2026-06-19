# frozen_string_literal: true

module ActiveReporter
  module Evaluator
    class Block < ActiveReporter::Evaluator::Base
      def evaluate(*args)
        block.call(*args)
      end

      private

      def block
        options.fetch(:block)
      end
    end
  end
end
