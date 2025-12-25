module FormBuilder
  module Conditions
    class OrCondition < BaseCondition
      attr_reader :conditions

      def initialize(conditions:)
        @conditions = conditions
      end

      def evaluate(responses)
        conditions.any? { |condition| condition.evaluate(responses) }
      end

      def description
        conditions.map(&:description).join("\n   <OR Visible> ")
      end

      def type
        'OR'
      end
    end
  end
end
