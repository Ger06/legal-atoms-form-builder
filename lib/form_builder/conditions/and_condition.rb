module FormBuilder
  module Conditions
    class AndCondition < BaseCondition
      attr_reader :conditions

      def initialize(conditions:)
        @conditions = conditions
      end

      def evaluate(responses)
        conditions.all? { |condition| condition.evaluate(responses) }
      end

      def description
        conditions.map(&:description).join("\n   <AND Visible> ")
      end

      def type
        'AND'
      end
    end
  end
end
