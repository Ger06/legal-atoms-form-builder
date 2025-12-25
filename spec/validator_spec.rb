require 'spec_helper'

RSpec.describe FormBuilder::Validator do
  describe '.validate' do
    it 'validates a correct configuration' do
      config = {
        'id' => 'test',
        'title' => 'Test Questionnaire',
        'questions' => [
          {
            'id' => 'name',
            'type' => 'text',
            'text' => 'What is your name?',
            'max_length' => 100
          }
        ]
      }

      expect { described_class.validate(config) }.not_to raise_error
    end

    it 'raises an error for missing required fields' do
      config = {
        'id' => 'test',
        'questions' => []
      }

      expect { described_class.validate(config) }.to raise_error(FormBuilder::ValidationError)
    end

    it 'raises an error for invalid question type' do
      config = {
        'id' => 'test',
        'title' => 'Test',
        'questions' => [
          {
            'id' => 'invalid',
            'type' => 'invalid_type',
            'text' => 'Invalid question'
          }
        ]
      }

      expect { described_class.validate(config) }.to raise_error(FormBuilder::ValidationError)
    end
  end

  describe '.validate_file' do
    it 'validates a YAML file' do
      expect { described_class.validate_file('config/personal_information.yaml') }.not_to raise_error
    end
  end
end
