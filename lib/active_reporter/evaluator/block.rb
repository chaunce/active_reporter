module ActiveReporter
  module Evaluator
    class Block < ActiveReporter::Evaluator::Base
      def evaluate(*args)
        block.call(*args)
      end

      private

      def block
        opts.fetch(:block)
      end
    end
  end
end
