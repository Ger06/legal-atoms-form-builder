module FormBuilder
  module Questions
    class CheckboxQuestion < BaseQuestion
      attr_reader :options, :allow_none, :allow_other

      def initialize(id:, text:, options: [], preset: nil, allow_none: false, allow_other: false, visibility_condition: nil)
        super(id: id, text: text, visibility_condition: visibility_condition)
        @options = preset ? Presets.get(preset) : options
        @allow_other = allow_other
        @allow_none = allow_none
      end

      def render(responses)
        output = "#{text} #{colorize('(checkbox question)', :light_black)}\n"

        response_values = get_response(responses) || []
        options.each do |option|
          marker = checkbox_marker(response_values.include?(option[:value]))
          label = response_values.include?(option[:value]) ? colorize(option[:label], :green) : option[:label]
          output += "   - [#{marker}] #{label}"
          output += " (value: '#{option[:value]}')" if option[:show_value]
          output += "\n"
        end

        if allow_other
          marker = checkbox_marker(response_values.include?('_'))
          other_label = response_values.include?('_') ? colorize('Other', :green) : 'Other'
          output += "   - [#{marker}] #{other_label} (value: '_')\n"
        end

        if allow_none
          marker = checkbox_marker(response_values.include?('none_of_the_above'))
          none_label = response_values.include?('none_of_the_above') ? colorize('None of the above', :green) : 'None of the above'
          output += "   - [#{marker}] #{none_label} (value: 'none_of_the_above')\n"
        end

        output += render_visibility if visibility_condition

        output
      end

      private

      def get_response(responses)
        responses.dig(id)
      end

      def render_visibility
        "   <Visible> #{visibility_condition.description}\n"
      end
    end
  end
end
