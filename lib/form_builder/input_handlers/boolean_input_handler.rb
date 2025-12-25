module FormBuilder
  module InputHandlers
    class BooleanInputHandler < BaseInputHandler
      VALID_TRUE = ['y', 'yes', '1', 'true'].freeze
      VALID_FALSE = ['n', 'no', '2', 'false'].freeze

      def prompt
        print "> (y/n): "
        gets.chomp.downcase
      end

      def validate(input)
        VALID_TRUE.include?(input) || VALID_FALSE.include?(input)
      end

      def parse(input)
        VALID_TRUE.include?(input)
      end

      def show_error
        puts colorize("  ✗ Error: Enter 'y' or 'n'", :red)
      end
    end
  end
end
