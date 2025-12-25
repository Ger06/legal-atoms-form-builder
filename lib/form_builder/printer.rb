module FormBuilder
  class Printer
    attr_reader :questionnaire

    def initialize(questionnaire)
      @questionnaire = questionnaire
    end

    def print(all_responses)
      output = "#{colorize("**#{questionnaire.title.upcase}**", :blue, :bold)}\n\n"

      responses = all_responses.dig(questionnaire.id) || {}
      visible_questions = questionnaire.visible_questions(all_responses)

      visible_questions.each_with_index do |question, index|
        question_number = colorize("#{index + 1}.", :cyan)
        output += "#{question_number} #{question.render(responses)}"
        output += "\n"
      end

      output
    end

    private

    def colorize(text, *colors)
      Colorizer.colorize(text, *colors)
    end
  end
end
