module FormBuilder
  module Conditions
    class ValueCheckCondition < BaseCondition
      attr_reader :question_id, :question_text, :expected_value

      def initialize(question_id:, question_text:, expected_value:)
        @question_id = question_id
        @question_text = question_text
        @expected_value = expected_value
      end

      def evaluate(responses)
        actual_value = responses.dig(question_id)
        actual_value == expected_value
      end

      def description
        "#{question_text}: #{expected_value}"
      end
    end
  end
end
