module FormBuilder
  module Questions
    class TextQuestion < BaseQuestion
      attr_reader :min_length, :max_length

      def initialize(id:, text:, min_length: nil, max_length: nil, visibility_condition: nil)
        super(id: id, text: text, visibility_condition: visibility_condition)
        @min_length = min_length
        @max_length = max_length
      end

      def render(responses)
        output = "#{text} #{colorize('(text question)', :light_black)}\n"

        constraints = []
        constraints << "at least <#{min_length}> characters" if min_length
        constraints << "at most <#{max_length}> characters" if max_length

        output += "   You can enter #{constraints.join(' and ')}.\n" unless constraints.empty?
        output += render_visibility if visibility_condition

        output
      end

      private

      def render_visibility
        "   <Visible> #{visibility_condition.description}\n"
      end
    end
  end
end
