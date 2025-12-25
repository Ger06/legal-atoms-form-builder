module FormBuilder
  module Questions
    class DropdownQuestion < BaseQuestion
      attr_reader :options

      def initialize(id:, text:, options: [], preset: nil, visibility_condition: nil)
        super(id: id, text: text, visibility_condition: visibility_condition)
        @options = preset ? Presets.get(preset) : options
      end

      def render(responses)
        output = "#{text} #{colorize('(dropdown question)', :light_black)}\n"
        output += render_visibility if visibility_condition

        response_value = get_response(responses)
        options.each do |option|
          marker = selected_marker(response_value == option[:value])
          label = response_value == option[:value] ? colorize(option[:label], :green) : option[:label]
          output += "   - <#{marker}> #{label}"
          output += " (value: '#{option[:value]}')" if option[:show_value]
          output += "\n"
        end

        output
      end

      private

      def get_response(responses)
        responses.dig(id)
      end

      def render_visibility
        "   <#{visibility_condition.type} Visible> #{visibility_condition.description}\n"
      end
    end
  end
end
