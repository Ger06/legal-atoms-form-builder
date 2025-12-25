require 'colorize'

module FormBuilder
  class Colorizer
    @enabled = $stdout.tty?

    class << self
      attr_accessor :enabled

      def colorize(text, *colors)
        return text unless enabled

        result = text
        colors.flatten.each do |color|
          result = result.colorize(color)
        end
        result
      end

      def disable!
        @enabled = false
      end

      def enable!
        @enabled = true
      end
    end
  end
end
