module FormBuilder
  module Questions
    class BaseQuestion
      attr_reader :id, :text, :visibility_condition

      def initialize(id:, text:, visibility_condition: nil)
        @id = id
        @text = text
        @visibility_condition = visibility_condition
      end

      def visible?(responses)
        return true unless visibility_condition

        visibility_condition.evaluate(responses)
      end

      def render(responses)
        raise NotImplementedError, 'Subclasses must implement render method'
      end

      protected

      def selected_marker(selected)
        selected ? 'x' : ' '
      end

      def checkbox_marker(selected)
        selected ? 'x' : ' '
      end

      def colorize(text, *colors)
        FormBuilder::Colorizer.colorize(text, *colors)
      end
    end
  end
end
