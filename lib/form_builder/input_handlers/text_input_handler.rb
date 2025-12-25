module FormBuilder
  module InputHandlers
    class TextInputHandler < BaseInputHandler
      def prompt
        constraints = []
        constraints << "min #{question.min_length} chars" if question.min_length
        constraints << "max #{question.max_length} chars" if question.max_length

        print "  "
        puts colorize("(#{constraints.join(', ')})", :light_black) unless constraints.empty?
        print "> "
        gets.chomp
      end

      def validate(input)
        return false if question.min_length && input.length < question.min_length
        return false if question.max_length && input.length > question.max_length
        true
      end

      def parse(input)
        input
      end

      def show_error
        errors = []
        errors << "Minimum #{question.min_length} characters" if question.min_length
        errors << "Maximum #{question.max_length} characters" if question.max_length
        puts colorize("  ✗ Error: #{errors.join(', ')}", :red)
      end
    end
  end
end
