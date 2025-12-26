if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'

    add_group 'Questions', 'lib/form_builder/questions'
    add_group 'Conditions', 'lib/form_builder/conditions'
    add_group 'Core', 'lib/form_builder'

    minimum_coverage 65
  end
end

require_relative '../lib/form_builder'

RSpec.configure do |config|
  config.before(:suite) do
    FormBuilder::Colorizer.disable!
  end
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
