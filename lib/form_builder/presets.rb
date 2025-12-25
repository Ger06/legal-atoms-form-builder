module FormBuilder
  class Presets
    PRESETS = {
      'genders' => [
        { label: 'Male', value: 'male', show_value: true },
        { label: 'Female', value: 'female', show_value: true },
        { label: 'X', value: 'x', show_value: false }
      ],
      'ethnicities' => [
        { label: 'White', value: 'white', show_value: true },
        { label: 'Black', value: 'black', show_value: true },
        { label: 'Asian', value: 'asian', show_value: true },
        { label: 'Hispanic', value: 'hispanic', show_value: true }
      ],
      'us_states' => [
        { label: 'California', value: 'ca', show_value: true },
        { label: 'Florida', value: 'fl', show_value: true },
        { label: 'New York', value: 'ny', show_value: true },
        { label: 'Texas', value: 'tx', show_value: true },
        { label: 'Washington', value: 'wa', show_value: true }
      ],
      'countries' => [
        { label: 'Canada', value: 'ca', show_value: true },
        { label: 'Mexico', value: 'mx', show_value: true },
        { label: 'United States', value: 'us', show_value: true }
      ]
    }.freeze

    def self.get(preset_name)
      PRESETS[preset_name] || []
    end
  end
end
