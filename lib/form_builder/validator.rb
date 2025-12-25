module FormBuilder
  class Validator
    SCHEMA_PATH = File.join(__dir__, '../../schema/questionnaire_schema.json')

    def self.validate(config_hash)
      schema = JSON.parse(File.read(SCHEMA_PATH))
      errors = JSON::Validator.fully_validate(schema, config_hash)

      if errors.any?
        raise ValidationError, "Configuration validation failed:\n#{errors.join("\n")}"
      end

      true
    end

    def self.validate_file(file_path)
      config = YAML.load_file(file_path)
      validate(config)
    end
  end

  class ValidationError < StandardError; end
end
