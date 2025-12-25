module FormBuilder
  module InputHandlers
    class RadioInputHandler < BaseInputHandler
      def prompt
        question.options.each_with_index do |option, index|
          puts "  #{index + 1}. #{option[:label]}"
        end
        print "> Number (1-#{question.options.length}): "
        gets.chomp
      end

      def validate(input)
        return false unless input.match?(/^\d+$/)
        num = input.to_i
        num >= 1 && num <= question.options.length
      end

      def parse(input)
        question.options[input.to_i - 1][:value]
      end

      def show_error
        puts colorize("  ✗ Error: Select number between 1 and #{question.options.length}", :red)
      end
    end
  end
end
