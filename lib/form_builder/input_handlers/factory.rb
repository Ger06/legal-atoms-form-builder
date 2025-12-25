module FormBuilder
  module InputHandlers
    class Factory
      def self.get_handler(question)
        case question
        when Questions::TextQuestion
          TextInputHandler.new(question)
        when Questions::BooleanQuestion
          BooleanInputHandler.new(question)
        when Questions::RadioQuestion
          RadioInputHandler.new(question)
        when Questions::CheckboxQuestion
          CheckboxInputHandler.new(question)
        when Questions::DropdownQuestion
          DropdownInputHandler.new(question)
        else
          raise "Unknown question type: #{question.class}"
        end
      end
    end
  end
end
