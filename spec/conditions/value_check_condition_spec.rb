require 'spec_helper'

RSpec.describe FormBuilder::Conditions::ValueCheckCondition do
  describe '#evaluate' do
    let(:condition) do
      described_class.new(
        question_id: 'have_alias',
        question_text: 'Do you have an alias?',
        expected_value: true
      )
    end

    it 'returns true when the response matches the expected value' do
      responses = { 'have_alias' => true }
      expect(condition.evaluate(responses)).to be true
    end

    it 'returns false when the response does not match the expected value' do
      responses = { 'have_alias' => false }
      expect(condition.evaluate(responses)).to be false
    end

    it 'returns false when the question is not answered' do
      responses = {}
      expect(condition.evaluate(responses)).to be false
    end
  end

  describe '#description' do
    it 'returns a human-readable description' do
      condition = described_class.new(
        question_id: 'have_alias',
        question_text: 'Do you have an alias?',
        expected_value: true
      )
      expect(condition.description).to eq('Do you have an alias?: true')
    end
  end
end
