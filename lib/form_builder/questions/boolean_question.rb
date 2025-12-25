module FormBuilder
  module Questions
    class BooleanQuestion < BaseQuestion
      def render(responses)
        output = "#{text} #{colorize('(boolean question)', :light_black)}\n"

        response_value = get_response(responses)
        yes_label = response_value == true ? colorize('Yes', :green) : 'Yes'
        no_label = response_value == false ? colorize('No', :green) : 'No'

        output += "   - (#{selected_marker(response_value == true)}) #{yes_label} (value: true)\n"
        output += "   - (#{selected_marker(response_value == false)}) #{no_label} (value: false)\n"
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
