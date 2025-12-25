require 'spec_helper'

RSpec.describe FormBuilder::Questions::TextQuestion do
  describe '#render' do
    it 'renders a text question with min and max length' do
      question = described_class.new(
        id: 'name',
        text: 'What is your name?',
        min_length: 10,
        max_length: 100
      )

      output = question.render({})
      expect(output).to include('What is your name? (text question)')
      expect(output).to include('You can enter at least <10> characters and at most <100> characters.')
    end

    it 'renders a text question with only max length' do
      question = described_class.new(
        id: 'alias',
        text: 'What is your alias?',
        max_length: 200
      )

      output = question.render({})
      expect(output).to include('What is your alias? (text question)')
      expect(output).to include('You can enter at most <200> characters.')
    end

    it 'renders visibility condition when present' do
      condition = FormBuilder::Conditions::ValueCheckCondition.new(
        question_id: 'have_alias',
        question_text: 'Do you have an alias?',
        expected_value: true
      )

      question = described_class.new(
        id: 'alias',
        text: 'What is your alias?',
        max_length: 200,
        visibility_condition: condition
      )

      output = question.render({})
      expect(output).to include('<Visible> Do you have an alias?: true')
    end
  end

  describe '#visible?' do
    it 'returns true when no visibility condition is set' do
      question = described_class.new(id: 'name', text: 'What is your name?')
      expect(question.visible?({})).to be true
    end

    it 'returns true when visibility condition is met' do
      condition = FormBuilder::Conditions::ValueCheckCondition.new(
        question_id: 'have_alias',
        question_text: 'Do you have an alias?',
        expected_value: true
      )

      question = described_class.new(
        id: 'alias',
        text: 'What is your alias?',
        visibility_condition: condition
      )

      expect(question.visible?({ 'have_alias' => true })).to be true
    end

    it 'returns false when visibility condition is not met' do
      condition = FormBuilder::Conditions::ValueCheckCondition.new(
        question_id: 'have_alias',
        question_text: 'Do you have an alias?',
        expected_value: true
      )

      question = described_class.new(
        id: 'alias',
        text: 'What is your alias?',
        visibility_condition: condition
      )

      expect(question.visible?({ 'have_alias' => false })).to be false
    end
  end
end
