#!/usr/bin/env ruby

require 'optparse'
require_relative 'lib/form_builder'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: questionnaire.rb --config file1.yaml,file2.yaml [--responses responses.yaml] [--interactive]"

  opts.on("--config CONFIG", "Comma-separated list of questionnaire config files") do |config|
    options[:config] = config.split(',').map(&:strip)
  end

  opts.on("--responses RESPONSES", "Path to responses YAML file (optional in interactive mode)") do |responses|
    options[:responses] = responses
  end

  opts.on("--interactive", "Run in interactive mode") do
    options[:interactive] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:config].nil?
  puts "Error: --config is required"
  puts "Usage: ruby questionnaire.rb --config file1.yaml,file2.yaml [--responses responses.yaml] [--interactive]"
  exit 1
end

if !options[:interactive] && options[:responses].nil?
  puts "Error: --responses is required when not in interactive mode"
  puts "Usage: ruby questionnaire.rb --config file1.yaml,file2.yaml --responses responses.yaml"
  puts "   or: ruby questionnaire.rb --config file1.yaml,file2.yaml --interactive"
  exit 1
end

begin
  questionnaires = options[:config].map do |config_file|
    FormBuilder::Questionnaire.from_yaml(config_file, validate: false)
  end

  if options[:interactive]
    # Modo interactivo
    runner = FormBuilder::InteractiveRunner.new(questionnaires)
    runner.run
  else
    # Modo YAML original
    responses = YAML.load_file(options[:responses])

    questionnaires.each do |questionnaire|
      puts questionnaire.print(responses)
    end
  end
rescue Errno::ENOENT => e
  puts "Error: File not found - #{e.message}"
  exit 1
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
  exit 1
end
