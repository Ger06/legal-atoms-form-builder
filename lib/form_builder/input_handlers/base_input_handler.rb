module FormBuilder
  module InputHandlers
    class BaseInputHandler
      attr_reader :question

      def initialize(question)
        @question = question
      end

      def get_input
        loop do
          input = prompt
          if validate(input)
            return parse(input)
          else
            show_error
          end
        end
      end

      def prompt
        raise NotImplementedError, 'Subclasses must implement prompt method'
      end

      def validate(input)
        raise NotImplementedError, 'Subclasses must implement validate method'
      end

      def parse(input)
        raise NotImplementedError, 'Subclasses must implement parse method'
      end

      def show_error
        puts colorize("  ✗ Error: Invalid input", :red)
      end

      protected

      def colorize(text, *colors)
        FormBuilder::Colorizer.colorize(text, *colors)
      end
    end
  end
end
