# Legal Atoms Form Builder - Complete Technical Documentation

**Author:** Gerard Perez
**GitHub:** [@Ger06](https://github.com/Ger06)
**Repository:** [legal-atoms-form-builder](https://github.com/Ger06/legal-atoms-form-builder)
**Date:** December 2025

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Design Patterns](#architecture--design-patterns)
3. [Step-by-Step Implementation](#step-by-step-implementation)
4. [Clean Code Principles Applied](#clean-code-principles-applied)
5. [Bonus Features Implemented](#bonus-features-implemented)
6. [Testing Strategy](#testing-strategy)
7. [CI/CD & DevOps](#cicd--devops)
8. [Future Improvements & Roadmap](#future-improvements--roadmap)
9. [Interview Q&A](#interview-qa)
10. [Database Integration Proposal](#database-integration-proposal)

---

## Project Overview

### What is This Project?

A **flexible and extensible form builder** for creating dynamic questionnaires with conditional visibility logic. Built entirely in Ruby, this CLI tool supports:

- **5 Question Types**: Text, Boolean, Radio, Checkbox, Dropdown
- **Complex Visibility Conditions**: value_check, AND, OR, NOT (composable)
- **YAML Configuration**: Human-readable questionnaire definitions
- **Dual Execution Modes**:
  - YAML mode: Pre-filled responses from file
  - Interactive mode: Real-time terminal prompts with validation
- **Professional Output**: Colorized terminal rendering
- **JSON Schema Validation**: Automatic config validation
- **Full Test Coverage**: RSpec suite with SimpleCov (67%+ coverage)
- **CI/CD**: GitHub Actions pipeline
- **Docker Support**: Containerized execution

### Why This Matters

Legal services often require collecting complex, conditional information from clients. This form builder demonstrates:

1. **Business Logic Complexity**: Handling nested conditional visibility
2. **Code Quality**: Clean architecture, SOLID principles, design patterns
3. **Production Readiness**: Tests, CI/CD, Docker, documentation
4. **User Experience**: Interactive mode with validation and colored output
5. **Extensibility**: Easy to add new question types, conditions, or storage backends

---

## Architecture & Design Patterns

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Entry Point                            │
│                   questionnaire.rb                          │
│              (CLI argument parsing)                         │
└───────────────┬─────────────────────────────────────────────┘
                │
        ┌───────▼────────┐
        │  Mode Selection │
        └───────┬────────┘
                │
    ┌───────────┴───────────┐
    │                       │
┌───▼────────┐      ┌───────▼──────────┐
│ YAML Mode  │      │ Interactive Mode │
│  Printer   │      │ InteractiveRunner│
└───┬────────┘      └───────┬──────────┘
    │                       │
    │               ┌───────▼──────────┐
    │               │ InputHandlers    │
    │               │   (Factory)      │
    │               └───────┬──────────┘
    │                       │
    └───────────┬───────────┘
                │
        ┌───────▼────────┐
        │  Core Domain   │
        │  Questionnaire │
        └───────┬────────┘
                │
    ┌───────────┴───────────┐
    │                       │
┌───▼─────────┐      ┌──────▼─────────┐
│  Questions  │      │  Conditions    │
│   (5 types) │      │  (4 types)     │
└─────────────┘      └────────────────┘
```

### Design Patterns Implemented

#### 1. **Strategy Pattern** (Conditions)

**Problem:** Different visibility evaluation logic for each condition type.

**Solution:** Define a common interface (`BaseCondition`) with polymorphic `evaluate` method.

```ruby
# lib/form_builder/conditions/base_condition.rb
module FormBuilder
  module Conditions
    class BaseCondition
      def evaluate(responses)
        raise NotImplementedError, 'Subclasses must implement evaluate'
      end
    end
  end
end

# lib/form_builder/conditions/value_check_condition.rb
class ValueCheckCondition < BaseCondition
  def evaluate(responses)
    response_value = responses.dig(@questionnaire_id, @question_id)
    response_value == @expected_value
  end
end

# lib/form_builder/conditions/and_condition.rb
class AndCondition < BaseCondition
  def evaluate(responses)
    @conditions.all? { |condition| condition.evaluate(responses) }
  end
end
```

**Benefits:**
- Easy to add new condition types (just extend `BaseCondition`)
- Client code doesn't know about specific implementations
- Testable in isolation

---

#### 2. **Template Method Pattern** (Questions)

**Problem:** Each question type has unique rendering logic but shares common structure.

**Solution:** Abstract class with common flow, subclasses override specific steps.

```ruby
# lib/form_builder/questions/base_question.rb
class BaseQuestion
  def render(responses)
    output = "#{@text} #{render_type_label}\n"
    output += render_constraints
    output += render_response(responses)
    output += render_visibility_info if @visibility
    output
  end

  # Template methods - subclasses override
  def render_type_label
    raise NotImplementedError
  end

  def render_response(responses)
    raise NotImplementedError
  end
end

# lib/form_builder/questions/text_question.rb
class TextQuestion < BaseQuestion
  def render_type_label
    colorize("(text question)", :light_black)
  end

  def render_response(responses)
    response = responses.dig(@questionnaire_id, @id)
    return "" unless response
    "   Answer: #{response}\n"
  end
end
```

**Benefits:**
- Code reuse for common rendering logic
- Each subclass focuses on its unique behavior
- Easy to understand the flow

---

#### 3. **Factory Pattern** (Input Handlers)

**Problem:** Need to create different input handlers based on question type in interactive mode.

**Solution:** Factory class that encapsulates creation logic.

```ruby
# lib/form_builder/input_handlers/factory.rb
module FormBuilder
  module InputHandlers
    class Factory
      def self.get_handler(question)
        case question.class.name.split('::').last
        when 'TextQuestion'
          TextInputHandler.new(question)
        when 'BooleanQuestion'
          BooleanInputHandler.new(question)
        when 'RadioQuestion'
          RadioInputHandler.new(question)
        when 'CheckboxQuestion'
          CheckboxInputHandler.new(question)
        when 'DropdownQuestion'
          DropdownInputHandler.new(question)
        else
          raise "Unknown question type: #{question.class}"
        end
      end
    end
  end
end

# Usage in InteractiveRunner
handler = InputHandlers::Factory.get_handler(question)
answer = handler.get_input
```

**Benefits:**
- Single Responsibility: Factory handles object creation
- Client code doesn't need to know handler classes
- Easy to add new handlers

---

#### 4. **Composite Pattern** (Nested Conditions)

**Problem:** Conditions can be nested arbitrarily (AND of ORs, NOT of ANDs, etc.)

**Solution:** Conditions can contain other conditions, forming a tree structure.

```ruby
# Example: Complex nested condition
visibility:
  type: and
  conditions:
    - type: value_check
      question_id: live_in_us
      expected_value: true
    - type: or
      conditions:
        - type: value_check
          question_id: situation
          expected_value: 'dv'
        - type: value_check
          question_id: situation
          expected_value: 'sa'
    - type: not
      condition:
        type: value_check
        question_id: has_lawyer
        expected_value: true

# Evaluates to: live_in_us == true AND
#               (situation == 'dv' OR situation == 'sa') AND
#               NOT(has_lawyer == true)
```

**Benefits:**
- Unlimited nesting depth
- Readable YAML configuration
- Each node only knows about its children

---

#### 5. **Dependency Injection** (Colorizer)

**Problem:** Need colors in production but not in tests.

**Solution:** Injectable configuration with global state management.

```ruby
# lib/form_builder/colorizer.rb
module FormBuilder
  class Colorizer
    @enabled = $stdout.tty?  # Auto-detect terminal

    class << self
      attr_accessor :enabled

      def colorize(text, *colors)
        return text unless enabled
        result = text
        colors.flatten.each { |color| result = result.colorize(color) }
        result
      end

      def enable!
        @enabled = true
      end

      def disable!
        @enabled = false
      end
    end
  end
end

# In tests (spec/spec_helper.rb)
RSpec.configure do |config|
  config.before(:suite) do
    FormBuilder::Colorizer.disable!
  end
end
```

**Benefits:**
- Tests verify plain text output
- Production has colorized output
- Single source of truth for color state

---

### SOLID Principles Applied

#### **S - Single Responsibility Principle**

Each class has one reason to change:

- `Questionnaire`: Load and manage questions
- `Printer`: Render questionnaire to terminal
- `Validator`: Validate YAML against JSON Schema
- `InteractiveRunner`: Orchestrate interactive flow
- `ResponseStorage`: Save responses to file
- Each `Question` type: Render its specific format
- Each `Condition` type: Evaluate its specific logic

**Example Violation Fixed:**
Initially, `Questionnaire` was handling both loading AND printing. Extracted `Printer` class:

```ruby
# Before (violates SRP)
class Questionnaire
  def print(responses)
    # 50 lines of rendering logic
  end
end

# After (follows SRP)
class Questionnaire
  # Only manages questions and visibility
end

class Printer
  def print(questionnaire, responses)
    # Dedicated to rendering
  end
end
```

---

#### **O - Open/Closed Principle**

Classes are open for extension, closed for modification.

**Example:** Adding a new question type requires NO changes to existing code:

```ruby
# To add "DateQuestion", just create new file:
class DateQuestion < BaseQuestion
  def render_type_label
    "(date question)"
  end

  def render_response(responses)
    # Date-specific rendering
  end
end

# Update factory (only place that needs change)
class Factory
  def self.get_handler(question)
    case question.class.name.split('::').last
    when 'DateQuestion'
      DateInputHandler.new(question)
    # ... existing cases
    end
  end
end
```

No changes needed to:
- `Questionnaire`
- `Printer`
- Other question types
- Condition classes

---

#### **L - Liskov Substitution Principle**

Any `BaseQuestion` subclass can replace `BaseQuestion` without breaking code.

```ruby
# This works for ANY question type
def print_question(question, responses)
  puts question.render(responses)  # Polymorphic call
  question.visible?(responses)     # Works for all types
end

text_q = TextQuestion.new(...)
bool_q = BooleanQuestion.new(...)

print_question(text_q, responses)  # Works
print_question(bool_q, responses)  # Works
```

All subclasses honor the base contract:
- `render(responses)` returns a string
- `visible?(responses)` returns boolean

---

#### **I - Interface Segregation Principle**

No class is forced to implement methods it doesn't use.

**Example:** InputHandlers have minimal required interface:

```ruby
class BaseInputHandler
  # Only 4 required methods
  def prompt         # Show input prompt
  def validate(input) # Check if valid
  def parse(input)   # Convert to proper type
  def show_error     # Display error message
end
```

Each handler only implements what it needs. No forced dependencies.

---

#### **D - Dependency Inversion Principle**

Depend on abstractions, not concrete classes.

**Example:** `InteractiveRunner` depends on `BaseInputHandler` abstraction:

```ruby
class InteractiveRunner
  def ask_question(questionnaire, question)
    # Depends on abstraction (any handler that implements get_input)
    handler = InputHandlers::Factory.get_handler(question)
    answer = handler.get_input  # Don't care which specific handler
  end
end
```

Runner doesn't know about `TextInputHandler`, `RadioInputHandler`, etc. Only knows about the interface.

---

## Step-by-Step Implementation

### Phase 1: Core Domain (Questions & Conditions)

**Goal:** Build the fundamental building blocks.

#### Step 1: Create Base Classes

```ruby
# lib/form_builder/questions/base_question.rb
module FormBuilder
  module Questions
    class BaseQuestion
      attr_reader :id, :type, :text, :visibility

      def initialize(data, questionnaire_id)
        @id = data['id']
        @type = data['type']
        @text = data['text']
        @questionnaire_id = questionnaire_id
        @visibility = parse_visibility(data['visibility'])
      end

      def visible?(responses)
        return true unless @visibility
        @visibility.evaluate(responses)
      end

      private

      def parse_visibility(visibility_data)
        return nil unless visibility_data
        Conditions::BaseCondition.from_hash(visibility_data)
      end
    end
  end
end
```

**Key Concepts for Ruby Beginners:**

1. **Module Namespacing:** `FormBuilder::Questions::BaseQuestion`
   - Organizes code into logical groups
   - Prevents naming conflicts
   - `FormBuilder` is the app namespace, `Questions` is the feature namespace

2. **`attr_reader`:** Creates getter methods
   ```ruby
   attr_reader :id  # Equivalent to:

   def id
     @id
   end
   ```

3. **Instance Variables:** `@id`, `@type` are accessible across all instance methods

4. **Conditional Assignment:**
   ```ruby
   return true unless @visibility
   # Equivalent to:
   if @visibility.nil?
     return true
   end
   ```

---

#### Step 2: Implement Concrete Question Types

```ruby
# lib/form_builder/questions/text_question.rb
class TextQuestion < BaseQuestion
  def initialize(data, questionnaire_id)
    super(data, questionnaire_id)
    @min_length = data['min_length']
    @max_length = data['max_length']
  end

  def render(responses)
    output = "#{@text} #{colorize('(text question)', :light_black)}\n"

    constraints = []
    constraints << "at least <#{@min_length}> characters" if @min_length
    constraints << "at most <#{@max_length}> characters" if @max_length
    output += "   You can enter #{constraints.join(' and ')}.\n" unless constraints.empty?

    response = responses.dig(@questionnaire_id, @id)
    output += "   Answer: #{response}\n" if response

    output += "   #{@visibility.description}\n" if @visibility
    output
  end
end
```

**Key Concepts:**

1. **`super`:** Calls parent class's initialize method
   ```ruby
   super(data, questionnaire_id)
   # Calls BaseQuestion.initialize(data, questionnaire_id)
   ```

2. **String Interpolation:** `"#{variable}"`
   ```ruby
   "at least <#{@min_length}> characters"
   # If @min_length = 10:
   # "at least <10> characters"
   ```

3. **Array Methods:**
   ```ruby
   constraints << "text"  # Append to array
   constraints.join(' and ')  # "item1 and item2 and item3"
   ```

4. **Hash `dig` Method:** Safely access nested hash
   ```ruby
   responses.dig('questionnaire_1', 'name')
   # Equivalent to:
   responses['questionnaire_1'] && responses['questionnaire_1']['name']
   # Returns nil if any level doesn't exist
   ```

---

#### Step 3: Implement Conditions

```ruby
# lib/form_builder/conditions/value_check_condition.rb
class ValueCheckCondition < BaseCondition
  def initialize(data)
    @questionnaire_id = data['questionnaire_id']
    @question_id = data['question_id']
    @question_text = data['question_text']
    @expected_value = data['expected_value']
  end

  def evaluate(responses)
    response_value = responses.dig(@questionnaire_id, @question_id)
    response_value == @expected_value
  end

  def description
    "<Visible> #{@question_text}: #{@expected_value}"
  end
end
```

**Key Concepts:**

1. **Boolean Return:** `evaluate` returns true/false
2. **Equality Check:** `==` compares values
   ```ruby
   response_value == @expected_value
   # true if equal, false otherwise
   ```

---

```ruby
# lib/form_builder/conditions/and_condition.rb
class AndCondition < BaseCondition
  def initialize(data)
    @conditions = data['conditions'].map do |condition_data|
      BaseCondition.from_hash(condition_data)
    end
  end

  def evaluate(responses)
    @conditions.all? { |condition| condition.evaluate(responses) }
  end
end
```

**Key Concepts:**

1. **`map` Method:** Transforms each array element
   ```ruby
   [1, 2, 3].map { |x| x * 2 }  # => [2, 4, 6]

   # Our case:
   conditions_data.map { |data| BaseCondition.from_hash(data) }
   # Converts each hash to a Condition object
   ```

2. **`all?` Method:** Returns true if ALL elements pass the block
   ```ruby
   [2, 4, 6].all? { |x| x.even? }  # => true
   [2, 3, 6].all? { |x| x.even? }  # => false

   # Our case:
   @conditions.all? { |c| c.evaluate(responses) }
   # Returns true only if ALL conditions evaluate to true
   ```

3. **Blocks:** `{ |param| code }`
   - Similar to anonymous functions/lambdas
   - `|condition|` is the block parameter
   - Code inside runs for each element

---

### Phase 2: YAML Configuration & Validation

#### Step 4: Questionnaire Loader

```ruby
# lib/form_builder/questionnaire.rb
class Questionnaire
  attr_reader :id, :title, :questions

  def self.from_yaml(file_path, validate: true)
    data = YAML.load_file(file_path)
    Validator.validate(data) if validate
    new(data)
  end

  def initialize(data)
    @id = data['id']
    @title = data['title']
    @questions = parse_questions(data['questions'])
  end

  def visible_questions(responses)
    @questions.select { |question| question.visible?(responses) }
  end

  private

  def parse_questions(questions_data)
    questions_data.map do |question_data|
      question_class = question_class_for_type(question_data['type'])
      question_class.new(question_data, @id)
    end
  end

  def question_class_for_type(type)
    case type
    when 'text' then Questions::TextQuestion
    when 'boolean' then Questions::BooleanQuestion
    when 'radio' then Questions::RadioQuestion
    when 'checkbox' then Questions::CheckboxQuestion
    when 'dropdown' then Questions::DropdownQuestion
    else
      raise "Unknown question type: #{type}"
    end
  end
end
```

**Key Concepts:**

1. **Class Methods:** `self.method_name`
   ```ruby
   def self.from_yaml(file_path)
     # Called like: Questionnaire.from_yaml('file.yaml')
     # NOT: questionnaire.from_yaml('file.yaml')
   end
   ```

2. **YAML Loading:**
   ```ruby
   YAML.load_file('config.yaml')
   # Returns Ruby hash/array from YAML file
   ```

3. **`select` Method:** Filters array
   ```ruby
   [1, 2, 3, 4].select { |x| x.even? }  # => [2, 4]

   # Our case:
   @questions.select { |q| q.visible?(responses) }
   # Returns only questions where visible? returns true
   ```

4. **Private Methods:** Only callable within the class
   ```ruby
   private

   def parse_questions(data)
     # Can only be called from other instance methods
     # NOT from outside: questionnaire.parse_questions(data) # Error!
   end
   ```

---

#### Step 5: JSON Schema Validation (BONUS)

```ruby
# lib/form_builder/validator.rb
require 'json-schema'

module FormBuilder
  class Validator
    SCHEMA_PATH = File.expand_path('../../schema/questionnaire_schema.json', __dir__)

    def self.validate(data)
      schema = JSON.parse(File.read(SCHEMA_PATH))

      errors = JSON::Validator.fully_validate(schema, data)

      unless errors.empty?
        raise "Invalid questionnaire configuration:\n#{errors.join("\n")}"
      end

      true
    end

    def self.validate_file(file_path)
      data = YAML.load_file(file_path)
      validate(data)
    end
  end
end
```

**Schema Example:**

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "required": ["id", "title", "questions"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-z_]+$"
    },
    "title": {
      "type": "string",
      "minLength": 1
    },
    "questions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "type", "text"],
        "properties": {
          "type": {
            "enum": ["text", "boolean", "radio", "checkbox", "dropdown"]
          }
        }
      }
    }
  }
}
```

**Benefits:**

1. **Early Error Detection:** Invalid configs fail before runtime
2. **Self-Documenting:** Schema shows exactly what's expected
3. **Validation Rules:**
   - Required fields
   - Type checking (string, array, object)
   - Pattern matching (regex)
   - Enum values
   - Min/max lengths

**Example Validation Error:**

```ruby
# Invalid YAML:
id: personal-info  # Should be snake_case
title: ""          # Should not be empty
questions: []      # Should have at least one question

# Error message:
# Invalid questionnaire configuration:
# The property '#/id' value "personal-info" did not match the regex '^[a-z_]+$'
# The property '#/title' did not have a minimum string length of 1
# The property '#/questions' did not contain a minimum number of items 1
```

---

### Phase 3: Interactive Mode (BONUS Feature)

#### Step 6: Input Handlers with Template Method

```ruby
# lib/form_builder/input_handlers/base_input_handler.rb
class BaseInputHandler
  attr_reader :question

  def initialize(question)
    @question = question
  end

  # Template method - orchestrates the flow
  def get_input
    loop do
      input = prompt
      if validate(input)
        return parse(input)
      else
        show_error
      end
    end
  end

  # Abstract methods - subclasses must implement
  def prompt
    raise NotImplementedError
  end

  def validate(input)
    raise NotImplementedError
  end

  def parse(input)
    raise NotImplementedError
  end

  def show_error
    raise NotImplementedError
  end

  protected

  def colorize(text, *colors)
    FormBuilder::Colorizer.colorize(text, *colors)
  end
end
```

**Key Concepts:**

1. **Loop Until Valid:**
   ```ruby
   loop do
     input = get_user_input
     if valid?(input)
       return input  # Exits loop
     else
       show_error   # Continues loop
     end
   end
   ```

2. **`raise NotImplementedError`:** Forces subclasses to implement
   ```ruby
   # If subclass doesn't override:
   handler.prompt  # => NotImplementedError: NotImplementedError
   ```

---

#### Step 7: Concrete Input Handlers

```ruby
# lib/form_builder/input_handlers/text_input_handler.rb
class TextInputHandler < BaseInputHandler
  def prompt
    constraints = []
    constraints << "min #{question.min_length} characters" if question.min_length
    constraints << "max #{question.max_length} characters" if question.max_length

    puts "  " + colorize("(#{constraints.join(', ')})", :light_black) unless constraints.empty?
    print "> "
    gets.chomp
  end

  def validate(input)
    return false if question.min_length && input.length < question.min_length
    return false if question.max_length && input.length > question.max_length
    true
  end

  def parse(input)
    input  # Already a string
  end

  def show_error
    errors = []
    errors << "Minimum #{question.min_length} characters" if question.min_length
    errors << "Maximum #{question.max_length} characters" if question.max_length
    puts colorize("  ✗ Error: #{errors.join(', ')}", :red)
  end
end
```

**Key Concepts:**

1. **`gets.chomp`:** Read user input from terminal
   ```ruby
   print "Enter name: "
   name = gets.chomp
   # User types: "John" and presses Enter
   # name = "John"
   #
   # Without .chomp, name would be "John\n" (includes newline)
   ```

2. **Guard Clauses:** Early return for invalid cases
   ```ruby
   # Instead of nested if:
   if question.min_length
     if input.length < question.min_length
       return false
     end
   end

   # Use guard clause:
   return false if question.min_length && input.length < question.min_length
   ```

---

```ruby
# lib/form_builder/input_handlers/radio_input_handler.rb
class RadioInputHandler < BaseInputHandler
  def prompt
    question.options.each_with_index do |option, index|
      puts "  #{index + 1}. #{option[:label]}"
    end
    print "> Number (1-#{question.options.length}): "
    gets.chomp
  end

  def validate(input)
    return false unless input.match?(/^\d+$/)  # Check if numeric
    num = input.to_i
    num >= 1 && num <= question.options.length
  end

  def parse(input)
    question.options[input.to_i - 1][:value]
  end

  def show_error
    puts colorize("  ✗ Error: Select number between 1 and #{question.options.length}", :red)
  end
end
```

**Key Concepts:**

1. **`each_with_index`:** Loop with index counter
   ```ruby
   ['a', 'b', 'c'].each_with_index do |item, index|
     puts "#{index}: #{item}"
   end
   # Output:
   # 0: a
   # 1: b
   # 2: c
   ```

2. **Regex Match:** `input.match?(/pattern/)`
   ```ruby
   "123".match?(/^\d+$/)  # => true (all digits)
   "12a".match?(/^\d+$/)  # => false (has letter)

   # Breakdown of /^\d+$/:
   # ^     = start of string
   # \d    = digit (0-9)
   # +     = one or more
   # $     = end of string
   ```

3. **String to Integer:** `"5".to_i => 5`

4. **Array Indexing:** Arrays are 0-indexed
   ```ruby
   options = [{label: 'A', value: 'a'}, {label: 'B', value: 'b'}]
   options[0]  # => {label: 'A', value: 'a'}
   options[1]  # => {label: 'B', value: 'b'}

   # User enters "1", we want options[0]:
   options[input.to_i - 1]
   ```

---

```ruby
# lib/form_builder/input_handlers/checkbox_input_handler.rb
class CheckboxInputHandler < BaseInputHandler
  def prompt
    available_options = build_options_list
    available_options.each_with_index do |option, index|
      puts "  #{index + 1}. #{option[:label]}"
    end
    print "> Numbers separated by comma (e.g., 1,3,5): "
    gets.chomp
  end

  def validate(input)
    return false if input.strip.empty?

    numbers = input.split(',').map(&:strip)
    max = build_options_list.length

    numbers.all? { |n| n.match?(/^\d+$/) && n.to_i >= 1 && n.to_i <= max }
  end

  def parse(input)
    options_list = build_options_list
    input.split(',').map(&:strip).map do |n|
      options_list[n.to_i - 1][:value]
    end
  end

  private

  def build_options_list
    list = question.options.dup
    list << { label: 'Other', value: '_' } if question.allow_other
    list << { label: 'None of the above', value: 'none_of_the_above' } if question.allow_none
    list
  end

  def show_error
    puts colorize("  ✗ Error: Enter valid numbers separated by comma", :red)
  end
end
```

**Key Concepts:**

1. **`split` Method:** Split string into array
   ```ruby
   "1,3,5".split(',')  # => ["1", "3", "5"]
   "a b c".split(' ')  # => ["a", "b", "c"]
   ```

2. **`map(&:method_name)` Shorthand:**
   ```ruby
   # Long form:
   ["  1", " 2 ", "3  "].map { |s| s.strip }  # => ["1", "2", "3"]

   # Shorthand using symbol-to-proc:
   ["  1", " 2 ", "3  "].map(&:strip)  # => ["1", "2", "3"]

   # Explanation:
   # &:strip converts symbol :strip to a proc that calls .strip
   ```

3. **Chaining `map`:**
   ```ruby
   input.split(',').map(&:strip).map { |n| options[n.to_i - 1][:value] }

   # Step by step:
   # "1,3,5"
   # .split(',')          => ["1", "3", "5"]
   # .map(&:strip)        => ["1", "3", "5"]
   # .map { |n| ... }     => ["value1", "value3", "value5"]
   ```

4. **`dup` Method:** Duplicate array/object
   ```ruby
   original = [1, 2, 3]
   copy = original.dup
   copy << 4
   # original => [1, 2, 3]
   # copy     => [1, 2, 3, 4]
   ```

---

#### Step 8: Interactive Runner Orchestration

```ruby
# lib/form_builder/interactive_runner.rb
class InteractiveRunner
  def initialize(questionnaires)
    @questionnaires = questionnaires
    @responses = {}
    @question_counter = 0
    Colorizer.enable!  # Force colors in interactive mode
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
      # Skip invisible questions
      next unless question.visible?(@responses)

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
  end

  def offer_save
    loop do
      print "\nSave responses? (y/n): "
      response = gets.chomp.downcase

      return unless response == 'y'

      path = prompt_for_path
      next if path.nil?  # User cancelled

      ResponseStorage.save(@responses, path)
      puts colorize("✓ Responses saved to #{path}", :green)
      break
    end
  end

  def prompt_for_path
    loop do
      print "File path (e.g., my_responses.yaml) - required: "
      path = gets.chomp.strip

      if path.empty?
        puts colorize("  ✗ Error: File path cannot be empty", :red)
        next
      end

      path += '.yaml' unless path.end_with?('.yaml')

      if File.exist?(path)
        return path if confirm_overwrite(path)
        next
      end

      return path
    end
  end

  def confirm_overwrite(path)
    print colorize("⚠ File '#{path}' already exists. Overwrite? (y/n): ", :yellow)
    response = gets.chomp.downcase

    if response != 'y'
      suggested = suggest_alternative_path(path)
      puts colorize("  Suggestion: #{suggested}", :cyan)
      return false
    end

    true
  end

  def suggest_alternative_path(path)
    base = path.sub(/\.yaml$/, '')
    counter = 2
    loop do
      suggested = "#{base}#{counter}.yaml"
      return suggested unless File.exist?(suggested)
      counter += 1
    end
  end

  def colorize(text, *colors)
    Colorizer.colorize(text, *colors)
  end
end
```

**Key Concepts:**

1. **`next` Keyword:** Skip to next iteration
   ```ruby
   [1, 2, 3, 4].each do |num|
     next if num.even?  # Skip even numbers
     puts num
   end
   # Output: 1, 3
   ```

2. **Nested Loops with Exit:**
   ```ruby
   loop do
     # Outer loop
     loop do
       # Inner loop
       break  # Exits inner loop only
     end
     break  # Exits outer loop
   end
   ```

3. **File Operations:**
   ```ruby
   File.exist?('file.txt')  # => true/false
   File.read('file.txt')    # => file contents as string
   ```

4. **Regex Substitution:**
   ```ruby
   "my_file.yaml".sub(/\.yaml$/, '')  # => "my_file"

   # Breakdown:
   # .sub(/pattern/, 'replacement')  # Replace first match
   # \.    = literal dot (escaped)
   # yaml  = literal text
   # $     = end of string
   ```

---

### Phase 4: Colorization & UX

#### Step 9: Colorizer Implementation

```ruby
# lib/form_builder/colorizer.rb
require 'colorize'

module FormBuilder
  class Colorizer
    @enabled = $stdout.tty?  # Detect if running in terminal

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

      def enable!
        @enabled = true
      end

      def disable!
        @enabled = false
      end
    end
  end
end
```

**Key Concepts:**

1. **Class Instance Variables:** `@enabled` at class level
   ```ruby
   class Colorizer
     @enabled = true  # Belongs to class, not instance

     class << self
       attr_accessor :enabled  # Creates class-level getter/setter
     end
   end

   # Usage:
   Colorizer.enabled = false  # Class method
   # NOT: Colorizer.new.enabled = false  # This wouldn't work
   ```

2. **`$stdout.tty?`:** Check if output is a terminal
   ```ruby
   # In terminal:
   $stdout.tty?  # => true

   # When redirecting to file:
   ruby script.rb > output.txt
   # Inside script: $stdout.tty? => false
   ```

3. **Splat Operator:** `*colors`
   ```ruby
   def colorize(text, *colors)
     # Collects all arguments after text into array
   end

   colorize("hello", :red, :bold)
   # text = "hello"
   # colors = [:red, :bold]
   ```

4. **`flatten` Method:**
   ```ruby
   [:red, [:bold, :underline]].flatten  # => [:red, :bold, :underline]

   # Useful for:
   colorize("text", :red, [:bold, :underline])
   # colors = [:red, [:bold, :underline]]
   # colors.flatten = [:red, :bold, :underline]
   ```

---

### Phase 5: Testing

#### Step 10: RSpec Test Suite

```ruby
# spec/spec_helper.rb
require 'simplecov'

if ENV['COVERAGE'] || ENV['CI']
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
    FormBuilder::Colorizer.disable!  # Disable colors in tests
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
```

**Example Test:**

```ruby
# spec/questions/text_question_spec.rb
RSpec.describe FormBuilder::Questions::TextQuestion do
  describe '#render' do
    it 'renders a text question with min and max length' do
      question = described_class.new({
        'id' => 'name',
        'type' => 'text',
        'text' => 'What is your name?',
        'min_length' => 10,
        'max_length' => 100
      }, 'personal_info')

      responses = {}
      output = question.render(responses)

      expect(output).to include('What is your name?')
      expect(output).to include('(text question)')
      expect(output).to include('at least <10> characters')
      expect(output).to include('at most <100> characters')
    end
  end

  describe '#visible?' do
    it 'returns true when visibility condition is met' do
      question = described_class.new({
        'id' => 'alias',
        'type' => 'text',
        'text' => 'What is your alias?',
        'visibility' => {
          'type' => 'value_check',
          'questionnaire_id' => 'personal_info',
          'question_id' => 'have_alias',
          'question_text' => 'Do you have an alias?',
          'expected_value' => true
        }
      }, 'personal_info')

      responses = {
        'personal_info' => {
          'have_alias' => true
        }
      }

      expect(question.visible?(responses)).to be true
    end
  end
end
```

**Key Testing Concepts:**

1. **`described_class`:** References the class being tested
   ```ruby
   RSpec.describe FormBuilder::Questions::TextQuestion do
     described_class  # => FormBuilder::Questions::TextQuestion
   end
   ```

2. **`expect` vs `should`:**
   ```ruby
   # Modern RSpec (expect):
   expect(output).to include('text')

   # Old style (should) - avoid:
   output.should include('text')
   ```

3. **Matchers:**
   ```ruby
   expect(value).to eq(5)           # Exact equality
   expect(value).to be > 3          # Comparison
   expect(value).to be_truthy       # Any truthy value
   expect(value).to be true         # Exact true
   expect(array).to include(item)   # Array/String contains
   expect { code }.to raise_error   # Expect exception
   ```

4. **Test Organization:**
   ```ruby
   RSpec.describe ClassName do
     describe '#method_name' do
       it 'does something specific' do
         # Arrange
         object = ClassName.new

         # Act
         result = object.method_name

         # Assert
         expect(result).to eq(expected)
       end
     end
   end
   ```

---

### Phase 6: CI/CD & Docker

#### Step 11: GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby-version: ['3.0', '3.1', '3.2']

    steps:
    - uses: actions/checkout@v4

    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ matrix.ruby-version }}
        bundler-cache: true

    - name: Run tests
      run: bundle exec rspec
      env:
        COVERAGE: true

    - name: Upload coverage reports
      if: matrix.ruby-version == '3.2'
      uses: codecov/codecov-action@v3
```

**Key Concepts:**

1. **Matrix Strategy:** Run tests on multiple Ruby versions
2. **Caching:** `bundler-cache: true` speeds up builds
3. **Conditional Steps:** `if: matrix.ruby-version == '3.2'`
4. **Environment Variables:** `COVERAGE: true`

---

#### Step 12: Docker Setup

```dockerfile
# Dockerfile
FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Default command
CMD ["bash"]
```

```yaml
# docker-compose.yml
services:
  app:
    build: .
    volumes:
      - .:/app
    stdin_open: true
    tty: true
    environment:
      - COVERAGE=false
```

**Key Docker Concepts:**

1. **Multi-stage builds:** Not used here, but good for production
2. **Volume mounting:** Changes in local files reflect in container
3. **stdin_open/tty:** Allows interactive input

---

## Clean Code Principles Applied

### 1. Meaningful Names

**Bad:**
```ruby
def calc(r)
  r.select { |q| q.v?(r) }
end
```

**Good:**
```ruby
def visible_questions(responses)
  questions.select { |question| question.visible?(responses) }
end
```

### 2. Functions Should Do One Thing

**Bad:**
```ruby
def process_questionnaire(file, responses, output_file)
  data = YAML.load_file(file)
  questionnaire = Questionnaire.new(data)
  visible = questionnaire.visible_questions(responses)
  output = ""
  visible.each { |q| output += q.render(responses) }
  File.write(output_file, output)
  puts "Done!"
end
```

**Good:**
```ruby
# Single responsibilities
questionnaire = Questionnaire.from_yaml(file)
visible_questions = questionnaire.visible_questions(responses)
output = Printer.print(questionnaire, responses)
File.write(output_file, output)
```

### 3. DRY (Don't Repeat Yourself)

**Bad:**
```ruby
class TextQuestion
  def render(responses)
    output = ""
    output += "#{@text} (text question)\n"
    output += "   #{@visibility.description}\n" if @visibility
    output
  end
end

class BooleanQuestion
  def render(responses)
    output = ""
    output += "#{@text} (boolean question)\n"
    output += "   #{@visibility.description}\n" if @visibility
    output
  end
end
```

**Good:**
```ruby
class BaseQuestion
  def render(responses)
    output = "#{@text} #{render_type_label}\n"
    output += "   #{@visibility.description}\n" if @visibility
    output
  end

  # Subclasses override
  def render_type_label
    raise NotImplementedError
  end
end
```

### 4. Error Handling

**Bad:**
```ruby
def load_questionnaire(file)
  YAML.load_file(file)
rescue
  nil
end
```

**Good:**
```ruby
def load_questionnaire(file)
  YAML.load_file(file)
rescue Errno::ENOENT => e
  raise "Questionnaire file not found: #{file}"
rescue Psych::SyntaxError => e
  raise "Invalid YAML syntax in #{file}: #{e.message}"
end
```

### 5. Comments vs Self-Documenting Code

**Bad:**
```ruby
# Check if the user's response matches the expected value
def evaluate(responses)
  # Get the response value from the responses hash
  rv = responses.dig(@qid, @quid)
  # Compare with expected
  rv == @ev
end
```

**Good:**
```ruby
def evaluate(responses)
  response_value = responses.dig(@questionnaire_id, @question_id)
  response_value == @expected_value
end
```

---

## Bonus Features Implemented

### 1. JSON Schema Validation ✅

**Implementation:**
- Schema file: `schema/questionnaire_schema.json`
- Validator class: `lib/form_builder/validator.rb`
- Auto-validation on load (can be disabled)

**Benefits:**
- Catches configuration errors early
- Serves as documentation
- Prevents runtime errors

**Example Validation:**
```ruby
# Invalid config
{
  "id": "invalid-id",  # Should be snake_case
  "title": "",         # Should not be empty
  "questions": []      # Should have at least one
}

# Error:
# Invalid questionnaire configuration:
# - The property '#/id' value "invalid-id" did not match the regex '^[a-z_]+$'
# - The property '#/title' did not have a minimum string length of 1
```

---

### 2. Interactive Mode ✅

**Features:**
- Question-by-question prompts
- Real-time validation
- Dynamic visibility evaluation
- File overwrite protection
- Colorized output

**Architecture:**
```
InteractiveRunner
    ├── InputHandlers::Factory
    │   ├── TextInputHandler
    │   ├── BooleanInputHandler
    │   ├── RadioInputHandler
    │   ├── CheckboxInputHandler
    │   └── DropdownInputHandler
    └── ResponseStorage
```

---

### 3. Colorized Terminal Output ✅

**Implementation:**
- Centralized `Colorizer` class
- TTY detection
- Test-friendly (can disable)

**Color Scheme:**
```ruby
# Titles
colorize("**QUESTIONNAIRE**", :blue, :bold)

# Question numbers
colorize("1.", :cyan)

# Success messages
colorize("✓ Saved", :green)

# Errors
colorize("✗ Error: Invalid input", :red)

# Metadata
colorize("(text question)", :light_black)

# Selected options
colorize("Yes", :green)
```

---

### 4. CI/CD Pipeline ✅

**GitHub Actions:**
- Runs on: push, pull_request
- Matrix: Ruby 3.0, 3.1, 3.2
- Steps:
  1. Checkout code
  2. Setup Ruby
  3. Install dependencies (cached)
  4. Run tests
  5. Upload coverage

**Badge:**
```markdown
[![CI](https://github.com/Ger06/legal-atoms-form-builder/actions/workflows/test.yml/badge.svg)](https://github.com/Ger06/legal-atoms-form-builder/actions/workflows/test.yml)
```

---

### 5. Code Coverage Reporting ✅

**SimpleCov Configuration:**
- Minimum coverage: 65%
- Grouped by module
- Filters: specs, vendor
- HTML reports

**Current Coverage:** 67.19%

---

### 6. Docker Support ✅

**Files:**
- `Dockerfile`: Ruby 3.2-slim image
- `docker-compose.yml`: Simplified commands
- `.dockerignore`: Exclude unnecessary files

**Commands:**
```bash
# Build
docker-compose build

# Run tests
docker-compose run --rm app bundle exec rspec

# Run YAML mode
docker-compose run --rm app ruby questionnaire.rb --config ... --responses ...

# Run interactive mode
docker-compose run --rm app ruby questionnaire.rb --config ... --interactive
```

---

## Testing Strategy

### Test Coverage by Module

```
Questions/         ✅ 85% coverage
├── TextQuestion         ✅ Fully tested
├── BooleanQuestion      ✅ Fully tested
├── RadioQuestion        ⚠️  Partially tested
├── CheckboxQuestion     ⚠️  Partially tested
└── DropdownQuestion     ⚠️  Partially tested

Conditions/        ✅ 90% coverage
├── ValueCheck           ✅ Fully tested
├── AndCondition         ✅ Fully tested
├── OrCondition          ⚠️  Partially tested
└── NotCondition         ⚠️  Partially tested

Core/              ⚠️  60% coverage
├── Questionnaire        ✅ Fully tested
├── Validator            ✅ Fully tested
├── Printer              ⚠️  Partially tested
├── InteractiveRunner    ❌ Not tested (requires mocking STDIN)
└── InputHandlers        ❌ Not tested (requires mocking STDIN)
```

### Test Types

**1. Unit Tests**
```ruby
# Test individual methods in isolation
describe '#visible?' do
  it 'returns true when condition is met' do
    question = TextQuestion.new(data, 'q1')
    responses = {'q1' => {'have_alias' => true}}
    expect(question.visible?(responses)).to be true
  end
end
```

**2. Integration Tests**
```ruby
# Test multiple components together
describe 'Questionnaire with visibility' do
  it 'shows only visible questions' do
    questionnaire = Questionnaire.from_yaml('spec/fixtures/questionnaire.yaml')
    responses = {'personal_info' => {'have_alias' => true}}

    visible = questionnaire.visible_questions(responses)
    expect(visible.map(&:id)).to include('alias')
  end
end
```

**3. Validation Tests**
```ruby
# Test error handling
describe 'Validator' do
  it 'raises error for invalid question type' do
    data = {'id' => 'q1', 'type' => 'invalid', 'questions' => []}
    expect { Validator.validate(data) }.to raise_error(/Invalid/)
  end
end
```

---

## CI/CD & DevOps

### GitHub Actions Workflow

**Triggers:**
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
```

**Matrix Testing:**
```yaml
strategy:
  matrix:
    ruby-version: ['3.0', '3.1', '3.2']
```

**Benefits:**
- ✅ Ensures compatibility across Ruby versions
- ✅ Catches breaking changes early
- ✅ Automated quality checks
- ✅ No manual testing needed

### Coverage Reporting

**SimpleCov Integration:**
```ruby
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Questions', 'lib/form_builder/questions'
  add_group 'Conditions', 'lib/form_builder/conditions'
  minimum_coverage 65
end
```

**HTML Report:**
```
coverage/index.html
├── Overall: 67.19%
├── Questions/: 85%
├── Conditions/: 90%
└── Core/: 60%
```

---

## Future Improvements & Roadmap

### Phase 1: Testing Enhancements (High Priority)

#### 1.1 Add Tests for Interactive Mode

**Challenge:** Interactive mode requires mocking STDIN/STDOUT.

**Solution:**

```ruby
# spec/interactive_runner_spec.rb
RSpec.describe FormBuilder::InteractiveRunner do
  describe '#run' do
    it 'collects responses interactively' do
      questionnaire = Questionnaire.from_yaml('spec/fixtures/simple.yaml')
      runner = InteractiveRunner.new([questionnaire])

      # Mock user input
      allow(runner).to receive(:gets).and_return("John Doe", "y", "my_responses.yaml", "y")

      # Capture output
      output = capture_stdout { runner.run }

      expect(output).to include("What is your name?")
      expect(output).to include("✓ Saved")
      expect(File.exist?('my_responses.yaml')).to be true
    end
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
```

**Benefits:**
- ✅ Tests user flow end-to-end
- ✅ Catches UX issues
- ✅ Coverage increases to 75%+

---

#### 1.2 Add Integration Tests for YAML Parsing

```ruby
# spec/integration/full_questionnaire_spec.rb
RSpec.describe 'Full questionnaire flow' do
  it 'loads, evaluates, and prints questionnaire' do
    # Create test questionnaire
    questionnaire_data = {
      'id' => 'test',
      'title' => 'Test Questionnaire',
      'questions' => [
        {
          'id' => 'name',
          'type' => 'text',
          'text' => 'Name?',
          'min_length' => 5
        },
        {
          'id' => 'age',
          'type' => 'text',
          'text' => 'Age?',
          'visibility' => {
            'type' => 'value_check',
            'questionnaire_id' => 'test',
            'question_id' => 'name',
            'expected_value' => 'John'
          }
        }
      ]
    }

    File.write('tmp/test.yaml', questionnaire_data.to_yaml)

    questionnaire = Questionnaire.from_yaml('tmp/test.yaml')
    responses = {'test' => {'name' => 'John'}}

    visible = questionnaire.visible_questions(responses)
    expect(visible.length).to eq(2)  # Both questions visible

    responses['test']['name'] = 'Jane'
    visible = questionnaire.visible_questions(responses)
    expect(visible.length).to eq(1)  # Only first question visible
  end
end
```

---

### Phase 2: Database Integration (Medium Priority)

#### 2.1 Why Add a Database?

**Current Limitations:**
- ❌ Responses stored in YAML files (not scalable)
- ❌ No user management
- ❌ No response history/versioning
- ❌ No analytics

**Use Cases:**
1. **Multi-user System:** Track which users submitted which responses
2. **Response History:** See how answers change over time
3. **Analytics:** Which questions are most commonly answered?
4. **Validation:** Prevent duplicate submissions
5. **Partial Saves:** Resume filling out a questionnaire later

---

#### 2.2 Database Choice: PostgreSQL

**Why PostgreSQL?**

1. **JSONB Support:** Perfect for storing dynamic questionnaire data
2. **Strong Data Integrity:** ACID compliance
3. **Advanced Queries:** Complex analytics
4. **Popular in Ruby Ecosystem:** Good ActiveRecord support
5. **Free & Open Source**

**Alternatives Considered:**

| Database | Pros | Cons | Verdict |
|----------|------|------|---------|
| **PostgreSQL** | JSONB, mature, powerful | Requires server | ✅ Best choice |
| MongoDB | Schema-less, easy | No joins, weak consistency | ❌ Overkill |
| SQLite | Simple, file-based | Limited concurrency | ⚠️ Good for dev only |
| MySQL | Popular, fast | No good JSON support | ❌ Weak for our needs |

---

#### 2.3 Database Schema Design

```sql
-- users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- questionnaires table
CREATE TABLE questionnaires (
  id VARCHAR(50) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  config JSONB NOT NULL,  -- Full YAML config as JSON
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- responses table
CREATE TABLE responses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  questionnaire_id VARCHAR(50) REFERENCES questionnaires(id),
  answers JSONB NOT NULL,  -- All answers as JSON
  status VARCHAR(20) DEFAULT 'in_progress',  -- in_progress, completed, submitted
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  submitted_at TIMESTAMP,
  UNIQUE(user_id, questionnaire_id)  -- One response per user per questionnaire
);

-- response_history table (for versioning)
CREATE TABLE response_history (
  id SERIAL PRIMARY KEY,
  response_id INTEGER REFERENCES responses(id),
  answers JSONB NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_responses_user_id ON responses(user_id);
CREATE INDEX idx_responses_questionnaire_id ON responses(questionnaire_id);
CREATE INDEX idx_responses_status ON responses(status);
CREATE INDEX idx_responses_answers ON responses USING GIN(answers);  -- JSONB index
```

**Schema Benefits:**

1. **JSONB Columns:**
   - `config`: Store full questionnaire definition
   - `answers`: Store all responses (flexible structure)
   - Queryable: `SELECT * FROM responses WHERE answers->>'name' = 'John'`

2. **Versioning:**
   - `response_history` tracks changes
   - Can reconstruct response at any point in time

3. **Status Tracking:**
   - `in_progress`: User started but didn't finish
   - `completed`: User finished but didn't submit
   - `submitted`: Final submission

---

#### 2.4 ActiveRecord Models

```ruby
# Gemfile
gem 'activerecord', '~> 7.0'
gem 'pg', '~> 1.5'

# lib/form_builder/models/base.rb
require 'active_record'

module FormBuilder
  module Models
    class Base < ActiveRecord::Base
      self.abstract_class = true

      # Configure database connection
      def self.configure_database(config)
        establish_connection(config)
      end
    end
  end
end

# lib/form_builder/models/user.rb
class User < FormBuilder::Models::Base
  has_many :responses
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end

# lib/form_builder/models/questionnaire_model.rb
class QuestionnaireModel < FormBuilder::Models::Base
  self.table_name = 'questionnaires'

  has_many :responses, foreign_key: 'questionnaire_id', primary_key: 'id'

  validates :id, presence: true, uniqueness: true
  validates :title, presence: true
  validates :config, presence: true

  # Load questionnaire from database
  def to_domain_object
    FormBuilder::Questionnaire.new(config)
  end

  # Save questionnaire to database
  def self.from_domain_object(questionnaire)
    create!(
      id: questionnaire.id,
      title: questionnaire.title,
      config: questionnaire.to_hash
    )
  end
end

# lib/form_builder/models/response.rb
class Response < FormBuilder::Models::Base
  belongs_to :user
  belongs_to :questionnaire_model, foreign_key: 'questionnaire_id', primary_key: 'id'
  has_many :response_histories, dependent: :destroy

  validates :user_id, presence: true
  validates :questionnaire_id, presence: true
  validates :answers, presence: true
  validates :status, inclusion: { in: %w[in_progress completed submitted] }

  before_update :create_history_entry

  # Mark as completed
  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end

  # Submit final response
  def submit!
    update!(status: 'submitted', submitted_at: Time.current)
  end

  # Get answer for specific question
  def answer_for(question_id)
    answers.dig(questionnaire_id, question_id)
  end

  # Update answer for specific question
  def update_answer(question_id, value)
    new_answers = answers.deep_dup
    new_answers[questionnaire_id] ||= {}
    new_answers[questionnaire_id][question_id] = value
    update!(answers: new_answers)
  end

  private

  def create_history_entry
    if answers_changed?
      response_histories.create!(
        answers: answers_was  # Previous version
      )
    end
  end
end

# lib/form_builder/models/response_history.rb
class ResponseHistory < FormBuilder::Models::Base
  belongs_to :response
end
```

---

#### 2.5 Database-Backed Interactive Runner

```ruby
# lib/form_builder/db_interactive_runner.rb
module FormBuilder
  class DBInteractiveRunner
    def initialize(questionnaire_id, user_id)
      @questionnaire_model = QuestionnaireModel.find(questionnaire_id)
      @questionnaire = @questionnaire_model.to_domain_object
      @user = User.find(user_id)
      @response = load_or_create_response
    end

    def run
      puts "Welcome, #{@user.name}!"

      if @response.status == 'submitted'
        puts "You already submitted this questionnaire."
        return
      end

      if @response.status == 'in_progress'
        puts "Resuming previous session..."
      end

      @questionnaire.questions.each do |question|
        next unless question.visible?(@response.answers)

        ask_question(question)
      end

      @response.complete!
      puts colorize("✓ All questions answered!", :green)

      if confirm_submission
        @response.submit!
        puts colorize("✓ Response submitted successfully!", :green)
      else
        puts "Response saved as draft. Resume anytime!"
      end
    end

    private

    def load_or_create_response
      Response.find_or_create_by!(
        user_id: @user.id,
        questionnaire_id: @questionnaire.id
      ) do |r|
        r.answers = {}
        r.status = 'in_progress'
      end
    end

    def ask_question(question)
      # Check if already answered
      existing_answer = @response.answer_for(question.id)

      if existing_answer
        print "#{question.text} (previously: #{existing_answer}) - "
        print colorize("Press Enter to keep, or type new answer: ", :yellow)
        input = gets.chomp
        return if input.strip.empty?  # Keep existing
      else
        puts "#{question.text}"
      end

      handler = InputHandlers::Factory.get_handler(question)
      answer = handler.get_input

      @response.update_answer(question.id, answer)
      puts colorize("  ✓ Saved", :green)
    end

    def confirm_submission
      print colorize("Submit final response? (y/n): ", :yellow)
      gets.chomp.downcase == 'y'
    end

    def colorize(text, *colors)
      Colorizer.colorize(text, *colors)
    end
  end
end
```

**New Features:**

1. **Resume Capability:**
   - Saves after each answer
   - Can quit and resume later
   - Shows previous answers

2. **User Management:**
   - Track who submitted what
   - Prevent duplicate submissions

3. **Status Workflow:**
   ```
   in_progress → completed → submitted
   ```

4. **History Tracking:**
   - Every update saved to history
   - Can see how answers changed

---

#### 2.6 Analytics & Reporting

```ruby
# lib/form_builder/analytics.rb
module FormBuilder
  class Analytics
    # Most answered questions
    def self.popular_questions(questionnaire_id)
      responses = Response.where(questionnaire_id: questionnaire_id)

      question_counts = Hash.new(0)

      responses.each do |response|
        response.answers.dig(questionnaire_id)&.each_key do |question_id|
          question_counts[question_id] += 1
        end
      end

      question_counts.sort_by { |_, count| -count }
    end

    # Common answer for a question
    def self.answer_distribution(questionnaire_id, question_id)
      responses = Response.where(questionnaire_id: questionnaire_id, status: 'submitted')

      answer_counts = Hash.new(0)

      responses.each do |response|
        answer = response.answer_for(question_id)
        answer_counts[answer] += 1 if answer
      end

      total = answer_counts.values.sum.to_f
      answer_counts.transform_values { |count| (count / total * 100).round(2) }
    end

    # Completion rate
    def self.completion_rate(questionnaire_id)
      total = Response.where(questionnaire_id: questionnaire_id).count
      return 0 if total.zero?

      completed = Response.where(questionnaire_id: questionnaire_id, status: 'submitted').count
      (completed / total.to_f * 100).round(2)
    end

    # Average time to complete
    def self.average_completion_time(questionnaire_id)
      responses = Response.where(questionnaire_id: questionnaire_id, status: 'submitted')
                          .where.not(submitted_at: nil)

      times = responses.map do |r|
        (r.submitted_at - r.started_at).to_i  # Seconds
      end

      return 0 if times.empty?

      times.sum / times.length  # Average seconds
    end

    # Report
    def self.generate_report(questionnaire_id)
      questionnaire = QuestionnaireModel.find(questionnaire_id)

      {
        questionnaire: {
          id: questionnaire.id,
          title: questionnaire.title
        },
        statistics: {
          total_responses: Response.where(questionnaire_id: questionnaire_id).count,
          submitted: Response.where(questionnaire_id: questionnaire_id, status: 'submitted').count,
          in_progress: Response.where(questionnaire_id: questionnaire_id, status: 'in_progress').count,
          completion_rate: "#{completion_rate(questionnaire_id)}%",
          avg_time: "#{average_completion_time(questionnaire_id) / 60} minutes"
        },
        question_popularity: popular_questions(questionnaire_id).first(10).to_h
      }
    end
  end
end

# Usage:
report = Analytics.generate_report('personal_information')
puts JSON.pretty_generate(report)

# Output:
# {
#   "questionnaire": {
#     "id": "personal_information",
#     "title": "Personal Information"
#   },
#   "statistics": {
#     "total_responses": 150,
#     "submitted": 120,
#     "in_progress": 30,
#     "completion_rate": "80.0%",
#     "avg_time": "5 minutes"
#   },
#   "question_popularity": {
#     "name": 150,
#     "gender": 145,
#     "have_alias": 140,
#     "alias": 75
#   }
# }
```

---

### Phase 3: Additional Question Types (Low Priority)

#### 3.1 Date Question

```ruby
# lib/form_builder/questions/date_question.rb
class DateQuestion < BaseQuestion
  def render(responses)
    output = "#{@text} #{colorize('(date question)', :light_black)}\n"

    response = responses.dig(@questionnaire_id, @id)
    if response
      output += "   Answer: #{response}\n"
    end

    output
  end
end

# lib/form_builder/input_handlers/date_input_handler.rb
class DateInputHandler < BaseInputHandler
  def prompt
    puts "  #{colorize('(Format: YYYY-MM-DD)', :light_black)}"
    print "> "
    gets.chomp
  end

  def validate(input)
    Date.parse(input)
    true
  rescue ArgumentError
    false
  end

  def parse(input)
    Date.parse(input).to_s
  end

  def show_error
    puts colorize("  ✗ Error: Invalid date format. Use YYYY-MM-DD", :red)
  end
end
```

**YAML Config:**
```yaml
- id: birthdate
  type: date
  text: What is your date of birth?
```

---

#### 3.2 Number Question (with Range)

```ruby
# lib/form_builder/questions/number_question.rb
class NumberQuestion < BaseQuestion
  attr_reader :min, :max

  def initialize(data, questionnaire_id)
    super
    @min = data['min']
    @max = data['max']
  end

  def render(responses)
    output = "#{@text} #{colorize('(number question)', :light_black)}\n"

    constraints = []
    constraints << "min: #{@min}" if @min
    constraints << "max: #{@max}" if @max
    output += "   #{constraints.join(', ')}\n" unless constraints.empty?

    response = responses.dig(@questionnaire_id, @id)
    output += "   Answer: #{response}\n" if response

    output
  end
end

# lib/form_builder/input_handlers/number_input_handler.rb
class NumberInputHandler < BaseInputHandler
  def prompt
    constraints = []
    constraints << "min: #{question.min}" if question.min
    constraints << "max: #{question.max}" if question.max

    puts "  #{colorize("(#{constraints.join(', ')})", :light_black)}" unless constraints.empty?
    print "> "
    gets.chomp
  end

  def validate(input)
    return false unless input.match?(/^-?\d+(\.\d+)?$/)  # Integer or decimal

    num = input.to_f
    return false if question.min && num < question.min
    return false if question.max && num > question.max

    true
  end

  def parse(input)
    input.include?('.') ? input.to_f : input.to_i
  end

  def show_error
    errors = []
    errors << "Must be a number"
    errors << "Minimum: #{question.min}" if question.min
    errors << "Maximum: #{question.max}" if question.max
    puts colorize("  ✗ Error: #{errors.join(', ')}", :red)
  end
end
```

**YAML Config:**
```yaml
- id: age
  type: number
  text: How old are you?
  min: 0
  max: 150
```

---

#### 3.3 File Upload Question

```ruby
# lib/form_builder/questions/file_question.rb
class FileQuestion < BaseQuestion
  attr_reader :allowed_types, :max_size_mb

  def initialize(data, questionnaire_id)
    super
    @allowed_types = data['allowed_types'] || []
    @max_size_mb = data['max_size_mb'] || 10
  end

  def render(responses)
    output = "#{@text} #{colorize('(file question)', :light_black)}\n"

    output += "   Allowed types: #{@allowed_types.join(', ')}\n" unless @allowed_types.empty?
    output += "   Max size: #{@max_size_mb}MB\n"

    response = responses.dig(@questionnaire_id, @id)
    output += "   Uploaded: #{response}\n" if response

    output
  end
end

# lib/form_builder/input_handlers/file_input_handler.rb
require 'fileutils'

class FileInputHandler < BaseInputHandler
  UPLOAD_DIR = 'uploads'

  def prompt
    puts "  #{colorize("(Allowed: #{question.allowed_types.join(', ')})", :light_black)}"
    print "> File path: "
    gets.chomp
  end

  def validate(input)
    return false unless File.exist?(input)

    ext = File.extname(input).downcase.delete('.')
    return false unless question.allowed_types.empty? || question.allowed_types.include?(ext)

    size_mb = File.size(input) / 1024.0 / 1024.0
    return false if size_mb > question.max_size_mb

    true
  end

  def parse(input)
    # Copy file to uploads directory
    FileUtils.mkdir_p(UPLOAD_DIR)

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "#{timestamp}_#{File.basename(input)}"
    dest = File.join(UPLOAD_DIR, filename)

    FileUtils.cp(input, dest)

    dest  # Return path to uploaded file
  end

  def show_error
    errors = []
    errors << "File must exist"
    errors << "Allowed types: #{question.allowed_types.join(', ')}" unless question.allowed_types.empty?
    errors << "Max size: #{question.max_size_mb}MB"
    puts colorize("  ✗ Error: #{errors.join(', ')}", :red)
  end
end
```

**YAML Config:**
```yaml
- id: resume
  type: file
  text: Upload your resume
  allowed_types: [pdf, doc, docx]
  max_size_mb: 5
```

---

### Phase 4: Advanced Features

#### 4.1 Conditional Logic Extensions

**4.1.1 Greater Than / Less Than Conditions**

```ruby
# lib/form_builder/conditions/comparison_condition.rb
class ComparisonCondition < BaseCondition
  def initialize(data)
    @questionnaire_id = data['questionnaire_id']
    @question_id = data['question_id']
    @operator = data['operator']  # 'gt', 'lt', 'gte', 'lte', 'eq', 'ne'
    @value = data['value']
  end

  def evaluate(responses)
    response_value = responses.dig(@questionnaire_id, @question_id)
    return false if response_value.nil?

    case @operator
    when 'gt' then response_value > @value
    when 'lt' then response_value < @value
    when 'gte' then response_value >= @value
    when 'lte' then response_value <= @value
    when 'eq' then response_value == @value
    when 'ne' then response_value != @value
    else
      raise "Unknown operator: #{@operator}"
    end
  end
end
```

**YAML Config:**
```yaml
- id: senior_discount
  type: boolean
  text: Qualify for senior discount?
  visibility:
    type: comparison
    questionnaire_id: personal_info
    question_id: age
    operator: gte
    value: 65
```

---

**4.1.2 Regex Match Condition**

```ruby
# lib/form_builder/conditions/regex_condition.rb
class RegexCondition < BaseCondition
  def initialize(data)
    @questionnaire_id = data['questionnaire_id']
    @question_id = data['question_id']
    @pattern = Regexp.new(data['pattern'])
  end

  def evaluate(responses)
    response_value = responses.dig(@questionnaire_id, @question_id)
    return false if response_value.nil?

    response_value.to_s.match?(@pattern)
  end
end
```

**YAML Config:**
```yaml
- id: verify_email
  type: boolean
  text: Send verification email?
  visibility:
    type: regex
    questionnaire_id: personal_info
    question_id: email
    pattern: ^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$
```

---

#### 4.2 Multi-Language Support

```ruby
# lib/form_builder/i18n.rb
module FormBuilder
  class I18n
    @locale = :en
    @translations = {}

    class << self
      attr_accessor :locale

      def load_translations(file_path)
        data = YAML.load_file(file_path)
        @translations.merge!(data)
      end

      def t(key, **options)
        keys = key.split('.')
        translation = @translations.dig(@locale.to_s, *keys)

        return key if translation.nil?

        # Interpolation
        options.each do |k, v|
          translation = translation.gsub("%{#{k}}", v.to_s)
        end

        translation
      end
    end
  end
end

# config/locales/en.yml
en:
  questions:
    text: "(text question)"
    boolean: "(boolean question)"
  errors:
    min_length: "Minimum %{count} characters"
    max_length: "Maximum %{count} characters"
  interactive:
    save_prompt: "Save responses? (y/n):"
    saved: "✓ Saved"

# config/locales/es.yml
es:
  questions:
    text: "(pregunta de texto)"
    boolean: "(pregunta booleana)"
  errors:
    min_length: "Mínimo %{count} caracteres"
    max_length: "Máximo %{count} caracteres"
  interactive:
    save_prompt: "¿Guardar respuestas? (y/n):"
    saved: "✓ Guardado"

# Usage:
I18n.locale = :es
I18n.load_translations('config/locales/es.yml')
puts I18n.t('questions.text')  # => "(pregunta de texto)"
puts I18n.t('errors.min_length', count: 10)  # => "Mínimo 10 caracteres"
```

---

#### 4.3 Export to Different Formats

```ruby
# lib/form_builder/exporters/pdf_exporter.rb
require 'prawn'

module FormBuilder
  module Exporters
    class PDFExporter
      def self.export(questionnaire, responses, output_path)
        Prawn::Document.generate(output_path) do |pdf|
          pdf.text questionnaire.title, size: 24, style: :bold
          pdf.move_down 20

          visible_questions = questionnaire.visible_questions(responses)

          visible_questions.each_with_index do |question, index|
            pdf.text "#{index + 1}. #{question.text}", size: 14

            answer = responses.dig(questionnaire.id, question.id)
            pdf.text "   Answer: #{answer}", size: 12 if answer

            pdf.move_down 10
          end
        end
      end
    end
  end
end

# lib/form_builder/exporters/csv_exporter.rb
require 'csv'

module FormBuilder
  module Exporters
    class CSVExporter
      def self.export(questionnaires, all_responses, output_path)
        # Collect all question IDs across all questionnaires
        question_ids = questionnaires.flat_map do |q|
          q.questions.map { |question| "#{q.id}.#{question.id}" }
        end

        CSV.open(output_path, 'w') do |csv|
          # Header row
          csv << ['Response ID', *question_ids]

          # Data rows
          all_responses.each_with_index do |(response_data, index)|
            row = [index + 1]

            question_ids.each do |full_id|
              q_id, question_id = full_id.split('.')
              answer = response_data.dig(q_id, question_id)
              row << answer
            end

            csv << row
          end
        end
      end
    end
  end
end

# Usage:
# PDF export
PDFExporter.export(questionnaire, responses, 'output.pdf')

# CSV export (for multiple responses)
all_responses = [
  {'personal_info' => {'name' => 'John', 'age' => 30}},
  {'personal_info' => {'name' => 'Jane', 'age' => 25}}
]
CSVExporter.export([questionnaire], all_responses, 'responses.csv')
```

---

## Interview Q&A

### Technical Questions

**Q1: Explain the difference between `include` and `extend` in Ruby modules.**

**A:**
- **`include`**: Adds module methods as **instance methods**
  ```ruby
  module Greetings
    def hello
      "Hello!"
    end
  end

  class Person
    include Greetings
  end

  person = Person.new
  person.hello  # => "Hello!" (instance method)
  ```

- **`extend`**: Adds module methods as **class methods**
  ```ruby
  class Person
    extend Greetings
  end

  Person.hello  # => "Hello!" (class method)
  ```

**In this project:**
```ruby
# We don't use extend, but if we wanted class methods:
module FormBuilder
  module Conditions
    module Factory
      def from_hash(data)
        # Factory logic
      end
    end
  end
end

class BaseCondition
  extend Conditions::Factory
end

BaseCondition.from_hash(data)  # Class method
```

---

**Q2: What is the difference between `==` and `equal?` in Ruby?**

**A:**
- **`==`**: Compares **values** (can be overridden)
  ```ruby
  "hello" == "hello"  # => true
  [1, 2] == [1, 2]    # => true
  ```

- **`equal?`**: Compares **object identity** (same object in memory)
  ```ruby
  a = "hello"
  b = "hello"
  a == b       # => true (same value)
  a.equal?(b)  # => false (different objects)

  c = a
  a.equal?(c)  # => true (same object)
  ```

**In this project:**
```ruby
# We use == for value comparison in conditions
def evaluate(responses)
  response_value == @expected_value  # Compare values, not objects
end
```

---

**Q3: Explain Ruby's `&:method_name` syntax.**

**A:** It's shorthand for converting a symbol to a proc.

**Long form:**
```ruby
names = ["john", "jane", "bob"]
names.map { |name| name.upcase }  # => ["JOHN", "JANE", "BOB"]
```

**Shorthand:**
```ruby
names.map(&:upcase)  # => ["JOHN", "JANE", "BOB"]
```

**How it works:**
1. `:upcase` is a symbol
2. `&` calls `to_proc` on the symbol
3. Symbol's `to_proc` returns `proc { |obj| obj.upcase }`
4. Block gets passed to `map`

**In this project:**
```ruby
# input_handlers/checkbox_input_handler.rb
input.split(',').map(&:strip)
# Equivalent to:
input.split(',').map { |s| s.strip }
```

---

**Q4: What are Ruby blocks, procs, and lambdas? What are the differences?**

**A:**

**Blocks:** Anonymous code chunks passed to methods
```ruby
[1, 2, 3].each { |n| puts n }
# or
[1, 2, 3].each do |n|
  puts n
end
```

**Procs:** Objects that hold blocks
```ruby
my_proc = Proc.new { |x| x * 2 }
my_proc.call(5)  # => 10
```

**Lambdas:** Special procs with strict argument checking
```ruby
my_lambda = ->(x) { x * 2 }
my_lambda.call(5)  # => 10
```

**Key Differences:**

| Feature | Proc | Lambda |
|---------|------|--------|
| Argument checking | Flexible | Strict |
| `return` behavior | Returns from enclosing method | Returns from lambda |

**Examples:**
```ruby
# Argument checking
my_proc = Proc.new { |x, y| x + y }
my_proc.call(1)  # => 1 (y is nil, but no error)

my_lambda = ->(x, y) { x + y }
my_lambda.call(1)  # => ArgumentError (wrong number of arguments)

# Return behavior
def test_proc
  my_proc = Proc.new { return "from proc" }
  my_proc.call
  "from method"
end

test_proc  # => "from proc" (returns from method)

def test_lambda
  my_lambda = -> { return "from lambda" }
  my_lambda.call
  "from method"
end

test_lambda  # => "from method" (returns from lambda only)
```

**In this project:**
```ruby
# We use blocks extensively
questions.select { |q| q.visible?(responses) }

# Could be rewritten with lambda:
visible = ->(q) { q.visible?(responses) }
questions.select(&visible)
```

---

**Q5: Explain the Strategy Pattern and where you used it in this project.**

**A:** Strategy Pattern defines a family of algorithms, encapsulates each one, and makes them interchangeable.

**Components:**
1. **Strategy Interface:** `BaseCondition` (abstract class)
2. **Concrete Strategies:** `ValueCheckCondition`, `AndCondition`, etc.
3. **Context:** `BaseQuestion` (uses conditions)

**Implementation:**
```ruby
# Strategy interface
class BaseCondition
  def evaluate(responses)
    raise NotImplementedError
  end
end

# Concrete strategies
class ValueCheckCondition < BaseCondition
  def evaluate(responses)
    response_value == @expected_value
  end
end

class AndCondition < BaseCondition
  def evaluate(responses)
    @conditions.all? { |c| c.evaluate(responses) }
  end
end

# Context uses strategy
class BaseQuestion
  def visible?(responses)
    return true unless @visibility
    @visibility.evaluate(responses)  # Polymorphic call
  end
end
```

**Benefits:**
- ✅ Easy to add new condition types
- ✅ Testable in isolation
- ✅ Follows Open/Closed Principle

---

**Q6: How did you ensure this project follows SOLID principles?**

**A:**

**S - Single Responsibility:**
- `Questionnaire`: Manages questions
- `Printer`: Renders output
- `Validator`: Validates config
- Each class has ONE reason to change

**O - Open/Closed:**
- Can add new question types without modifying existing code
- Just extend `BaseQuestion` and update factory

**L - Liskov Substitution:**
- Any `BaseQuestion` subclass can replace `BaseQuestion`
- Client code doesn't know about specific types

**I - Interface Segregation:**
- `BaseInputHandler` has minimal interface (4 methods)
- No forced dependencies

**D - Dependency Inversion:**
- `InteractiveRunner` depends on `BaseInputHandler` abstraction
- Not on concrete `TextInputHandler`, etc.

---

**Q7: What is a Factory Pattern and why did you use it?**

**A:** Factory Pattern provides an interface for creating objects without specifying exact classes.

**Problem:**
```ruby
# Without factory (bad):
if question.type == 'text'
  handler = TextInputHandler.new(question)
elsif question.type == 'boolean'
  handler = BooleanInputHandler.new(question)
# ... many more elsif
end
```

**Solution:**
```ruby
# With factory (good):
handler = InputHandlers::Factory.get_handler(question)
```

**Benefits:**
- ✅ Centralized object creation
- ✅ Client code doesn't know about concrete classes
- ✅ Easy to add new types

**Implementation:**
```ruby
class Factory
  def self.get_handler(question)
    case question.class.name.split('::').last
    when 'TextQuestion' then TextInputHandler.new(question)
    when 'BooleanQuestion' then BooleanInputHandler.new(question)
    # ...
    end
  end
end
```

---

**Q8: How would you add caching to improve performance?**

**A:**

**Problem:** Repeated visibility evaluations are expensive.

**Solution 1: Memoization**
```ruby
class BaseQuestion
  def visible?(responses)
    @visible_cache ||= {}
    cache_key = responses.hash

    @visible_cache[cache_key] ||= calculate_visibility(responses)
  end

  private

  def calculate_visibility(responses)
    return true unless @visibility
    @visibility.evaluate(responses)
  end
end
```

**Solution 2: Query Result Caching (with DB)**
```ruby
class Response
  def visible_question_ids
    Rails.cache.fetch("response_#{id}/visible_questions", expires_in: 1.hour) do
      questionnaire = questionnaire_model.to_domain_object
      questionnaire.visible_questions(answers).map(&:id)
    end
  end
end
```

**Solution 3: Compiled Conditions**
```ruby
# Instead of evaluating conditions every time,
# compile them to Ruby code once

class ValueCheckCondition
  def compile
    # Generate Ruby code as string
    "responses.dig(#{@questionnaire_id.inspect}, #{@question_id.inspect}) == #{@expected_value.inspect}"
  end
end

class AndCondition
  def compile
    compiled_conditions = @conditions.map(&:compile)
    "(#{compiled_conditions.join(' && ')})"
  end
end

# Usage:
condition = AndCondition.new(...)
code = condition.compile
# => "(responses.dig('q1', 'name') == 'John' && responses.dig('q1', 'age') > 18)"

# Eval once (security: only use with trusted input!)
compiled_proc = eval("lambda { |responses| #{code} }")
compiled_proc.call(responses)  # Fast!
```

---

### Behavioral Questions

**Q9: Describe a challenging bug you encountered in this project and how you solved it.**

**A:**

**Bug:** Colors not showing in Windows terminals during interactive mode, even though `$stdout.tty?` returned `true`.

**Investigation:**
1. Confirmed `Colorizer.enabled` was `true`
2. Checked if `colorize` gem was installed
3. Tested in different terminals (CMD, PowerShell, Git Bash)
4. Found that some Windows terminals report `tty? = true` but don't support ANSI colors

**Solution:**
```ruby
# Original (unreliable):
@enabled = $stdout.tty?

# Fixed (explicit control):
class InteractiveRunner
  def initialize(questionnaires)
    @questionnaires = questionnaires
    Colorizer.enable!  # Force colors in interactive mode
  end
end
```

**Lesson:** Don't rely solely on auto-detection. Provide manual overrides.

---

**Q10: How did you approach testing this project?**

**A:**

**Strategy:**
1. **Start with Core Domain:** Test questions and conditions first (highest value)
2. **Test Public Interfaces:** Focus on behavior, not implementation
3. **Use Fixtures:** YAML files for realistic test data
4. **Mock External Dependencies:** File I/O, STDIN/STDOUT

**Example Test Structure:**
```ruby
RSpec.describe FormBuilder::Questionnaire do
  describe '.from_yaml' do
    it 'loads a questionnaire from a YAML file' do
      # Arrange: Create fixture
      File.write('tmp/test.yaml', fixture_data.to_yaml)

      # Act: Load questionnaire
      questionnaire = Questionnaire.from_yaml('tmp/test.yaml')

      # Assert: Verify structure
      expect(questionnaire.id).to eq('test')
      expect(questionnaire.questions.length).to eq(3)
    end
  end
end
```

**Coverage Strategy:**
- Core logic: 90%+ coverage
- Edge cases: Comprehensive
- Happy paths: Essential
- Error handling: Critical

**What I'd improve:**
- Add integration tests for interactive mode (currently not tested)
- Add performance benchmarks
- Add mutation testing

---

**Q11: If you had 2 more weeks, what would you add?**

**A:**

**Week 1:**
1. **Database Integration** (3 days)
   - PostgreSQL setup
   - ActiveRecord models
   - Migration scripts
   - DB-backed interactive runner

2. **Comprehensive Testing** (2 days)
   - Interactive mode tests (mock STDIN)
   - Integration tests
   - Performance benchmarks
   - Increase coverage to 85%+

**Week 2:**
3. **Web Interface** (4 days)
   - Sinatra/Rails API
   - REST endpoints
   - React frontend (or server-rendered HTML)
   - User authentication

4. **Analytics Dashboard** (1 day)
   - Completion rates
   - Question popularity
   - Answer distributions
   - Export reports (PDF, CSV)

**Priority:** Database first (enables everything else).

---

**Q12: How do you handle code review feedback?**

**A:**

**My Process:**
1. **Read Fully:** Understand all feedback before responding
2. **Ask Questions:** If unclear, request clarification
3. **Categorize:**
   - **Must Fix:** Security, bugs, breaking changes
   - **Should Fix:** Code quality, readability
   - **Nice to Have:** Optimizations, style preferences
4. **Respond:** Acknowledge each comment
5. **Implement:** Make changes, explain if disagreeing
6. **Re-request Review:** Ask for another look

**Example from this project:**

*Reviewer:* "The `InteractiveRunner#ask_question` method is doing too much. Consider extracting the handler logic."

*My Response:* "Great point! I see it's handling both input collection and response storage. I'll extract the handler creation to a factory method and the storage to a separate method."

*Changes:*
```ruby
# Before (one big method):
def ask_question(questionnaire, question)
  handler = case question.type
            when 'text' then TextInputHandler.new(question)
            # ... many cases
            end
  answer = handler.get_input
  @responses[questionnaire.id][question.id] = answer
  puts "✓ Saved"
end

# After (SRP):
def ask_question(questionnaire, question)
  handler = create_handler(question)
  answer = handler.get_input
  save_answer(questionnaire, question, answer)
end

def create_handler(question)
  InputHandlers::Factory.get_handler(question)
end

def save_answer(questionnaire, question, answer)
  @responses[questionnaire.id][question.id] = answer
  puts colorize("✓ Saved", :green)
end
```

---

## Database Integration Proposal

*(See Phase 2 above for full implementation)*

**Summary:**
- **Database:** PostgreSQL with JSONB
- **ORM:** ActiveRecord
- **Schema:** Users, Questionnaires, Responses, ResponseHistory
- **Features:**
  - Resume capability
  - User management
  - Response versioning
  - Analytics

---

## Conclusion

This project demonstrates:

✅ **Clean Architecture:** SOLID principles, design patterns
✅ **Ruby Proficiency:** OOP, modules, metaprogramming
✅ **Testing:** RSpec, coverage, CI/CD
✅ **DevOps:** Docker, GitHub Actions
✅ **Product Thinking:** UX (colors, interactive mode), extensibility
✅ **Documentation:** Comprehensive README, inline comments

**Future-Ready:**
- Database integration designed
- Additional question types planned
- Analytics roadmap defined
- Export functionality scoped

**My Learning:**
- First Ruby project → learned OOP patterns
- Implemented 6 design patterns
- Achieved 67% test coverage
- Deployed CI/CD pipeline
- Dockerized for portability

---

## Resources

### Documentation
- [Ruby Docs](https://ruby-doc.org/)
- [RSpec](https://rspec.info/)
- [JSON Schema](https://json-schema.org/)
- [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html)

### Tools Used
- **Language:** Ruby 3.2
- **Testing:** RSpec 3.12, SimpleCov 0.22
- **Validation:** json-schema 4.0
- **UI:** colorize 1.1
- **CI/CD:** GitHub Actions
- **Containerization:** Docker 28.0.1

---

**Thank you for reviewing my project!**
I'm excited to discuss any part of this implementation in detail.

Gerard Perez
[@Ger06](https://github.com/Ger06)
