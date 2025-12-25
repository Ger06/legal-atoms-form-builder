module FormBuilder
  module Conditions
    class NotCondition < BaseCondition
      attr_reader :condition

      def initialize(condition:)
        @condition = condition
      end

      def evaluate(responses)
        !condition.evaluate(responses)
      end

      def description
        "NOT #{condition.description}"
      end

      def type
        'NOT'
      end
    end
  end
end
