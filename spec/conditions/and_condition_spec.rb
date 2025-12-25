require 'spec_helper'

RSpec.describe FormBuilder::Conditions::AndCondition do
  describe '#evaluate' do
    let(:condition1) do
      FormBuilder::Conditions::ValueCheckCondition.new(
        question_id: 'live_in_us',
        question_text: 'Do you live in the US?',
        expected_value: true
      )
    end

    let(:condition2) do
      FormBuilder::Conditions::ValueCheckCondition.new(
        question_id: 'which_situation',
        question_text: 'Which situation best applies to you?',
        expected_value: 'dv'
      )
    end

    let(:and_condition) { described_class.new(conditions: [condition1, condition2]) }

    it 'returns true when all conditions are true' do
      responses = { 'live_in_us' => true, 'which_situation' => 'dv' }
      expect(and_condition.evaluate(responses)).to be true
    end

    it 'returns false when one condition is false' do
      responses = { 'live_in_us' => false, 'which_situation' => 'dv' }
      expect(and_condition.evaluate(responses)).to be false
    end

    it 'returns false when all conditions are false' do
      responses = { 'live_in_us' => false, 'which_situation' => 'sa' }
      expect(and_condition.evaluate(responses)).to be false
    end
  end
end
