# Form Builder

Implement a form builder that can be used to implement forms for different types of questionnaires.

## Feature Requirements

### Questionnaire

A questionnaire is a collection of questions. It can be configured with:
    - Title
    - A list of questions

### Question Types

1. A text question that can be configured with:
    - Minimum length
    - Maximum length

2. A checkbox question that can be configured with:
    - Options (each option has a label and a value)
    - None of the above
    - "Other" option that allows the user to type
    - Allow preset options for:
      - Ethnicities

3. A radio question that can be configured with:
    - Options (each option has a label and a value)
    - Allow preset options for:
      - Genders

4. A dropdown question that can be configured with:
    - Options (each option has a label and a value)
    - Allow preset options for:
      - States in the US (return 5 states)
      - Countries (return 3 countries)

5. A boolean question

### Visibility Conditions

Visibility conditions are used to determine whether a question should be visible to the user. Each visibility condition is configured against a question.

1. Value Check Condition: Checks whether the response to a question matches a specific value
2. And Condition: Checks whether all of the conditions are true
3. Or Condition: Checks whether any of the conditions are true
4. Not Condition: Checks whether a condition is false

## Technical Requirements

### API

Provide an API that we can use to dynamically print the questionnaire depending on the user response.

```
# 'personal_information' and 'about_the_situation' are the form ids.
# 'name', 'have_alias', 'which_situation', 'live_in_us' are the question ids.
user_response = {
  'personal_information' => {
    'name' => 'Ubba Huang',
    'have_alias' => true
  },
  'about_the_situation' => {
    'which_situation' => 'sa',
    'live_in_us' => false
  }
}
questionnaire.print(user_response)
```

Provide a Ruby script that can be executed and print the 

```
ruby questionnaire.rb --config personal_information.yaml,about_the_situation.yaml --responses user_response.yaml
```

### Terminal Printer Format

Configure and render the following 2 questionnaires to the user in the terminal in plain text format. Note the visibilities of certain questions. If they are not visible, then do not print them.

**Personal Information**

1. What is your name? (text question)
   You can enter at least <10> characters and at most <100> characters.

2. Do you have an alias? (boolean question)
   - (x) Yes (value: true)
   - ( ) No (value: false)

3. What is your alias? (text question)
   You can enter at most <200> characters.
   <Visible> Do you have an alias?: true

4. What is your gender? (radio question)
  - ( ) Male (value: 'male')
  - ( ) Female (value: 'female')
  - ( ) X

5. Select all that apply. (checkbox question)
  - [ ] White (value: 'white')
  - [ ] Black (value: 'black')
  - [ ] Asian (value: 'asian')
  - [ ] Hispanic (value: 'hispanic')
  - [ ] Other (value: '_')
  - [ ] None of the above (value: 'none_of_the_above')

**ABOUT THE SITUATION**

1. Which situation best applies to you? (radio question)
   - (x) Domestic Violence (value: 'dv')
   - ( ) Sexual Assault (value: 'sa')

2. Do you live in the US? (boolean question)
   - (x) Yes (value: true)
   - ( ) No (value: false)

3. What state do you live in? (dropdown question)
   <AND Visible> Do you live in the US?: true
   <AND Visible> Which situation best applies to you?: 'dv'
  - < > California (value: 'ca')
  - < > Florida (value: 'fl')
  - < > New York (value: 'ny')
  - < > Texas (value: 'tx')
  - < > Washington (value: 'wa')

4. What country do you live in? (dropdown question) # This is invisible.
   <Visible> Do you live in the US?: false
  - < > Canada (value: 'ca')
  - < > Mexico (value: 'mx')

### Configuration

Questionnaires need to be configurable YAML files.

### Testing

Include `rspec` unit tests.

### Code Quality

Write the cleanest most object-oriented code possible.

### Bonus

Apply JSON Schema validation to the questionnaire configuration.
