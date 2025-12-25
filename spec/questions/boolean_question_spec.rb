require 'spec_helper'

RSpec.describe FormBuilder::Questions::BooleanQuestion do
  describe '#render' do
    it 'renders a boolean question with no response' do
      question = described_class.new(
        id: 'have_alias',
        text: 'Do you have an alias?'
      )

      output = question.render({})
      expect(output).to include('Do you have an alias? (boolean question)')
      expect(output).to include('- ( ) Yes (value: true)')
      expect(output).to include('- ( ) No (value: false)')
    end

    it 'renders a boolean question with true response' do
      question = described_class.new(
        id: 'have_alias',
        text: 'Do you have an alias?'
      )

      output = question.render({ 'have_alias' => true })
      expect(output).to include('- (x) Yes (value: true)')
      expect(output).to include('- ( ) No (value: false)')
    end

    it 'renders a boolean question with false response' do
      question = described_class.new(
        id: 'live_in_us',
        text: 'Do you live in the US?'
      )

      output = question.render({ 'live_in_us' => false })
      expect(output).to include('- ( ) Yes (value: true)')
      expect(output).to include('- (x) No (value: false)')
    end
  end
end
