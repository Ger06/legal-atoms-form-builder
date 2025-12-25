module FormBuilder
  module InputHandlers
    class CheckboxInputHandler < BaseInputHandler
      def prompt
        available_options = build_options_list
        available_options.each_with_index do |option, index|
          puts "  #{index + 1}. #{option[:label]}"
        end
        print "> Numbers separated by comma (e.g., 1,3,5): "
        gets.chomp
      end

      def validate(input)
        return false if input.strip.empty?
        numbers = input.split(',').map(&:strip)
        max = build_options_list.length
        numbers.all? { |n| n.match?(/^\d+$/) && n.to_i >= 1 && n.to_i <= max }
      end

      def parse(input)
        options_list = build_options_list
        input.split(',').map(&:strip).map do |n|
          options_list[n.to_i - 1][:value]
        end
      end

      private

      def build_options_list
        list = question.options.dup
        list << { label: 'Other', value: '_' } if question.allow_other
        list << { label: 'None of the above', value: 'none_of_the_above' } if question.allow_none
        list
      end

      def show_error
        puts colorize("  ✗ Error: Enter valid numbers separated by comma", :red)
      end
    end
  end
end
