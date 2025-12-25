module FormBuilder
  class InteractiveRunner
    attr_reader :questionnaires

    def initialize(questionnaires)
      @questionnaires = questionnaires
      @responses = {}
      @question_counter = 0
      # Forzar colores habilitados en modo interactivo
      Colorizer.enable!
    end

    def run
      @questionnaires.each do |questionnaire|
        run_questionnaire(questionnaire)
      end

      offer_save
    end

    private

    def run_questionnaire(questionnaire)
      puts "\n#{colorize("**#{questionnaire.title.upcase}**", :blue, :bold)}\n\n"

      @responses[questionnaire.id] = {}

      questionnaire.questions.each do |question|
        next unless question.visible?(@responses.dig(questionnaire.id) || {})

        ask_question(questionnaire, question)
      end
    end

    def ask_question(questionnaire, question)
      @question_counter += 1
      puts "#{colorize("#{@question_counter}.", :cyan)} #{question.text}"

      handler = InputHandlers::Factory.get_handler(question)
      answer = handler.get_input

      @responses[questionnaire.id][question.id] = answer
      puts colorize("  ✓ Saved", :green)
      puts ""
    end

    def offer_save
      puts "\n#{colorize('='*50, :light_black)}"
      print "\nSave responses? (y/n): "
      return unless gets.chomp.downcase == 'y'

      path = nil
      loop do
        print "File path (e.g., my_responses.yaml) - required: "
        path = gets.chomp.strip

        # Validate non-empty input
        if path.empty?
          puts colorize("  ✗ Error: File path cannot be empty", :red)
          next
        end

        # Add .yaml extension if not present
        path += '.yaml' unless path.end_with?('.yaml')

        if File.exist?(path)
          print colorize("⚠ File '#{path}' already exists. Overwrite? (y/n): ", :yellow)
          response = gets.chomp.downcase

          if response == 'y'
            break
          else
            # Suggest alternative name
            base = path.sub(/\.yaml$/, '')
            counter = 2
            while File.exist?("#{base}#{counter}.yaml")
              counter += 1
            end
            suggested = "#{base}#{counter}.yaml"
            puts colorize("  Suggestion: #{suggested}", :cyan)
            next
          end
        else
          break
        end
      end

      ResponseStorage.save(@responses, path)
      puts colorize("\n✓ Responses saved to #{path}", :green)
    end

    def colorize(text, *colors)
      Colorizer.colorize(text, *colors)
    end
  end
end
