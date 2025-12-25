# Form Builder

[![CI](https://github.com/Ger06/legal-atoms-form-builder/actions/workflows/test.yml/badge.svg)](https://github.com/Ger06/legal-atoms-form-builder/actions/workflows/test.yml)
[![Ruby Version](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org/)
[![Code Coverage](https://img.shields.io/badge/coverage-70%25+-brightgreen.svg)](https://github.com/Ger06/legal-atoms-form-builder)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A flexible and extensible form builder for creating dynamic questionnaires with conditional visibility in Ruby.

## Features

- **Multiple Question Types**: Text, Boolean, Radio, Checkbox, and Dropdown questions
- **Visibility Conditions**: Dynamic question visibility based on user responses
- **Dual Execution Modes**: YAML-based and Interactive modes
- **Colorized Terminal Output**: Professional colored output for better readability
- **YAML Configuration**: Easy-to-write configuration files
- **Preset Options**: Built-in presets for common options (genders, ethnicities, US states, countries)
- **JSON Schema Validation**: Automatic validation of questionnaire configurations
- **Terminal Rendering**: Clean text-based output for terminal display
- **Object-Oriented Design**: Clean, maintainable, and extensible codebase
- **CI/CD Pipeline**: GitHub Actions for automated testing
- **Code Coverage**: SimpleCov integration with coverage reporting

## Prerequisites

- **Ruby 3.0+** (tested on Ruby 3.0, 3.1, and 3.2)
- **Bundler** for dependency management
- **Docker** (optional, for containerized execution)

## Installation

### Option 1: Using Bundler (Recommended)

```bash
bundle install
```

### Option 2: Using Docker (Optional)

If you prefer to run the project in a containerized environment:

```bash
docker-compose build
```

## Usage

### YAML Mode (Pre-filled Responses)

Run questionnaires with pre-filled responses from a YAML file:

```bash
ruby questionnaire.rb --config config/personal_information.yaml,config/about_the_situation.yaml --responses config/user_response.yaml
```

### Interactive Mode

Run questionnaires interactively, answering questions one by one:

```bash
ruby questionnaire.rb --config config/personal_information.yaml,config/about_the_situation.yaml --interactive
```

In interactive mode:
- Questions appear one at a time with colored prompts
- Only visible questions are shown based on your previous answers
- Input is validated in real-time with helpful error messages
- Save your responses to a YAML file at the end

### Using Docker

If you built the Docker image, you can run the project with:

```bash
# Run tests
docker-compose run app bundle exec rspec

# Run in YAML mode
docker-compose run app ruby questionnaire.rb --config config/personal_information.yaml,config/about_the_situation.yaml --responses config/user_response.yaml

# Run in interactive mode
docker-compose run app ruby questionnaire.rb --config config/personal_information.yaml,config/about_the_situation.yaml --interactive
```

### Configuration Format

Questionnaires are defined in YAML files with the following structure:

```yaml
id: questionnaire_id
title: Questionnaire Title
questions:
  - id: question_id
    type: text|boolean|radio|checkbox|dropdown
    text: Question text
    # Additional type-specific configuration
```

### Question Types

#### Text Question
```yaml
- id: name
  type: text
  text: What is your name?
  min_length: 10
  max_length: 100
```

#### Boolean Question
```yaml
- id: have_alias
  type: boolean
  text: Do you have an alias?
```

#### Radio Question
```yaml
- id: gender
  type: radio
  text: What is your gender?
  preset: genders  # Or use custom options
```

#### Checkbox Question
```yaml
- id: ethnicity
  type: checkbox
  text: Select all that apply.
  preset: ethnicities
  allow_other: true
  allow_none: true
```

#### Dropdown Question
```yaml
- id: state
  type: dropdown
  text: What state do you live in?
  preset: us_states
```

### Visibility Conditions

#### Value Check
```yaml
visibility:
  type: value_check
  question_id: have_alias
  question_text: Do you have an alias?
  expected_value: true
```

#### And Condition
```yaml
visibility:
  type: and
  conditions:
    - type: value_check
      question_id: live_in_us
      question_text: Do you live in the US?
      expected_value: true
    - type: value_check
      question_id: which_situation
      question_text: Which situation best applies to you?
      expected_value: dv
```

#### Or Condition
```yaml
visibility:
  type: or
  conditions:
    - type: value_check
      question_id: condition1
      question_text: Condition 1?
      expected_value: true
    - type: value_check
      question_id: condition2
      question_text: Condition 2?
      expected_value: false
```

#### Not Condition
```yaml
visibility:
  type: not
  condition:
    type: value_check
    question_id: some_question
    question_text: Some question?
    expected_value: false
```

### Presets

Available presets:
- `genders`: Male, Female, X
- `ethnicities`: White, Black, Asian, Hispanic
- `us_states`: California, Florida, New York, Texas, Washington
- `countries`: Canada, Mexico, United States

## Testing

Run the test suite:

```bash
bundle exec rspec
```

Run with coverage report:

```bash
COVERAGE=true bundle exec rspec
```

## Project Structure

```
.
├── lib/
│   └── form_builder/
│       ├── questions/              # Question type implementations
│       ├── conditions/             # Visibility condition implementations
│       ├── input_handlers/         # Interactive mode input handlers
│       │   ├── base_input_handler.rb
│       │   ├── factory.rb
│       │   ├── text_input_handler.rb
│       │   ├── boolean_input_handler.rb
│       │   ├── radio_input_handler.rb
│       │   ├── checkbox_input_handler.rb
│       │   └── dropdown_input_handler.rb
│       ├── questionnaire.rb        # Main questionnaire class
│       ├── printer.rb              # Terminal output renderer
│       ├── presets.rb              # Preset option definitions
│       ├── validator.rb            # JSON Schema validator
│       ├── colorizer.rb            # Color output manager
│       ├── interactive_runner.rb   # Interactive mode orchestrator
│       └── response_storage.rb     # YAML response persistence
├── config/                         # Example configuration files
├── schema/                         # JSON Schema for validation
├── spec/                           # RSpec tests
├── .github/workflows/              # CI/CD pipeline
├── Dockerfile                      # Docker configuration
├── docker-compose.yml              # Docker Compose configuration
└── questionnaire.rb                # Executable script

```

## Design Decisions

### Object-Oriented Architecture
- Each question type inherits from `BaseQuestion` with polymorphic rendering
- Visibility conditions follow the Strategy pattern for flexible composition
- Input handlers use Template Method pattern with validation loop
- Factory pattern for creating appropriate input handlers per question type
- Separation of concerns: configuration loading, business logic, and presentation are distinct

### Dual Execution Modes
- **YAML Mode**: Traditional approach with pre-filled responses from YAML file
- **Interactive Mode**: Real-time user input with validation and conditional visibility
- Both modes share the same core question and condition logic for consistency

### Colorized Output
- Centralized `Colorizer` class manages terminal color output
- Automatically detects TTY support for compatibility
- Can be disabled for testing to ensure clean output verification
- Enhances readability with semantic colors (errors in red, success in green, prompts in cyan)

### YAML Configuration
- Human-readable and easy to write
- Supports complex nested structures for visibility conditions
- Validated against JSON Schema for correctness

### Extensibility
- New question types can be added by extending `BaseQuestion`
- New visibility conditions can be added by extending `BaseCondition`
- New input handlers can be added by extending `BaseInputHandler`
- New presets can be easily added to the `Presets` class

## Bonus Features

### JSON Schema Validation
The project includes automatic validation of questionnaire configurations against a JSON Schema. This ensures:
- Required fields are present
- Data types are correct
- Enum values are valid
- Nested structures are properly formed

Validation can be disabled if needed:
```ruby
Questionnaire.from_yaml('config.yaml', validate: false)
```

### Interactive Mode
A fully interactive questionnaire experience:
- Answer questions one at a time in the terminal
- Real-time input validation with helpful error messages
- Dynamic visibility - only see questions relevant to your answers
- Save responses to YAML file when complete
- Colorized prompts and feedback for better UX

### Colorized Terminal Output
Professional colored output enhances readability:
- Blue bold titles for questionnaire sections
- Cyan question numbers
- Green highlights for selected options
- Red error messages
- Gray metadata text
- Automatically disabled in test environment

### CI/CD Pipeline
GitHub Actions workflow for automated testing:
- Tests run on Ruby 3.0, 3.1, and 3.2
- Automatic execution on push and pull requests
- Coverage reports uploaded to Codecov
- Ensures code quality and cross-version compatibility

### Code Coverage Reporting
SimpleCov integration provides:
- Line-by-line coverage analysis
- Grouped coverage by module (Questions, Conditions, etc.)
- Minimum coverage thresholds
- HTML reports for detailed inspection
- CI integration for automated tracking

## Example Output

### YAML Mode Output

```
**PERSONAL INFORMATION**  (in blue)

1. What is your name? (text question)  (1. in cyan, (text question) in gray)
   You can enter at least <10> characters and at most <100> characters.
   Answer: Gerard Perez

2. Do you have an alias? (boolean question)
   - (x) Yes (value: true)  (Yes in green)
   - ( ) No (value: false)

3. What is your alias? (text question)
   You can enter at most <200> characters.
   <Visible> Do you have an alias?: true
   Answer: GP
```

### Interactive Mode Example

```
**PERSONAL INFORMATION**  (in blue)

1. What is your name?  (1. in cyan)
  (min 10 characters, max 100 characters)  (in gray)
> Gerard Perez
  ✓ Saved  (in green)

2. Do you have an alias?
> y
  ✓ Saved

3. What is your alias?
  (max 200 characters)
> GP
  ✓ Saved

**ABOUT THE SITUATION**

4. Which situation best applies to you?
  1. Bankruptcy
  2. Discrimination
  3. Divorce
  4. Domestic violence
> Number (1-4): 3
  ✓ Saved

Save responses? (y/n): y
File path (e.g., my_responses.yaml) - required: my_answers.yaml
✓ Responses saved to my_answers.yaml  (in green)
```

## Author

Built with clean, object-oriented Ruby following SOLID principles.
