module FormBuilder
  class ResponseStorage
    def self.save(responses, file_path)
      File.write(file_path, YAML.dump(responses))
    end
  end
end
