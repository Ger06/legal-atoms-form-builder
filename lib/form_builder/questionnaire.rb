module FormBuilder
  class Questionnaire
    attr_reader :id, :title, :questions

    def initialize(id:, title:, questions:)
      @id = id
      @title = title
      @questions = questions
    end

    def self.from_yaml(file_path, validate: true)
      config = YAML.load_file(file_path)
      Validator.validate(config) if validate
      new(
        id: config['id'],
        title: config['title'],
        questions: build_questions(config['questions'])
      )
    end

    def print(responses)
      Printer.new(self).print(responses)
    end

    def visible_questions(responses)
      questions.select { |question| question.visible?(responses.dig(id) || {}) }
    end

    private

    def self.build_questions(questions_config)
      questions_config.map do |question_config|
        build_question(question_config)
      end
    end

    def self.build_question(config)
      type = config['type']
      visibility_condition = build_visibility_condition(config['visibility'])

      case type
      when 'text'
        Questions::TextQuestion.new(
          id: config['id'],
          text: config['text'],
          min_length: config['min_length'],
          max_length: config['max_length'],
          visibility_condition: visibility_condition
        )
      when 'boolean'
        Questions::BooleanQuestion.new(
          id: config['id'],
          text: config['text'],
          visibility_condition: visibility_condition
        )
      when 'radio'
        Questions::RadioQuestion.new(
          id: config['id'],
          text: config['text'],
          options: parse_options(config['options']),
          preset: config['preset'],
          visibility_condition: visibility_condition
        )
      when 'checkbox'
        Questions::CheckboxQuestion.new(
          id: config['id'],
          text: config['text'],
          options: parse_options(config['options']),
          preset: config['preset'],
          allow_none: config['allow_none'] || false,
          allow_other: config['allow_other'] || false,
          visibility_condition: visibility_condition
        )
      when 'dropdown'
        Questions::DropdownQuestion.new(
          id: config['id'],
          text: config['text'],
          options: parse_options(config['options']),
          preset: config['preset'],
          visibility_condition: visibility_condition
        )
      else
        raise "Unknown question type: #{type}"
      end
    end

    def self.build_visibility_condition(visibility_config)
      return nil unless visibility_config

      type = visibility_config['type']

      case type
      when 'value_check'
        Conditions::ValueCheckCondition.new(
          question_id: visibility_config['question_id'],
          question_text: visibility_config['question_text'],
          expected_value: visibility_config['expected_value']
        )
      when 'and'
        conditions = visibility_config['conditions'].map { |cond| build_visibility_condition(cond) }
        Conditions::AndCondition.new(conditions: conditions)
      when 'or'
        conditions = visibility_config['conditions'].map { |cond| build_visibility_condition(cond) }
        Conditions::OrCondition.new(conditions: conditions)
      when 'not'
        condition = build_visibility_condition(visibility_config['condition'])
        Conditions::NotCondition.new(condition: condition)
      else
        raise "Unknown visibility condition type: #{type}"
      end
    end

    def self.parse_options(options)
      return [] unless options

      options.map do |option|
        {
          label: option['label'],
          value: option['value'],
          show_value: option['show_value'] != false
        }
      end
    end
  end
end
