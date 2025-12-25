require 'spec_helper'

RSpec.describe FormBuilder::Questionnaire do
  describe '.from_yaml' do
    let(:yaml_path) { 'config/personal_information.yaml' }

    it 'loads a questionnaire from a YAML file' do
      questionnaire = described_class.from_yaml(yaml_path)

      expect(questionnaire.id).to eq('personal_information')
      expect(questionnaire.title).to eq('Personal Information')
      expect(questionnaire.questions.length).to eq(5)
    end

    it 'creates questions with correct types' do
      questionnaire = described_class.from_yaml(yaml_path)

      expect(questionnaire.questions[0]).to be_a(FormBuilder::Questions::TextQuestion)
      expect(questionnaire.questions[1]).to be_a(FormBuilder::Questions::BooleanQuestion)
      expect(questionnaire.questions[2]).to be_a(FormBuilder::Questions::TextQuestion)
      expect(questionnaire.questions[3]).to be_a(FormBuilder::Questions::RadioQuestion)
      expect(questionnaire.questions[4]).to be_a(FormBuilder::Questions::CheckboxQuestion)
    end
  end

  describe '#visible_questions' do
    let(:questionnaire) { described_class.from_yaml('config/personal_information.yaml') }

    it 'returns all questions when no visibility conditions are active' do
      responses = {
        'personal_information' => {
          'have_alias' => false
        }
      }

      visible = questionnaire.visible_questions(responses)
      expect(visible.length).to eq(4)
    end

    it 'returns questions including conditionally visible ones' do
      responses = {
        'personal_information' => {
          'have_alias' => true
        }
      }

      visible = questionnaire.visible_questions(responses)
      expect(visible.length).to eq(5)
      expect(visible.map(&:id)).to include('alias')
    end
  end

  describe '#print' do
    let(:questionnaire) { described_class.from_yaml('config/about_the_situation.yaml') }

    it 'prints the questionnaire with visible questions' do
      responses = {
        'about_the_situation' => {
          'which_situation' => 'dv',
          'live_in_us' => true
        }
      }

      output = questionnaire.print(responses)
      expect(output).to include('**ABOUT THE SITUATION**')
      expect(output).to include('Which situation best applies to you?')
      expect(output).to include('Do you live in the US?')
      expect(output).to include('What state do you live in?')
      expect(output).not_to include('What country do you live in?')
    end
  end
end
