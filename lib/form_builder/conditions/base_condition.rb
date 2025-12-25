module FormBuilder
  module Conditions
    class BaseCondition
      def evaluate(responses)
        raise NotImplementedError, 'Subclasses must implement evaluate method'
      end

      def description
        raise NotImplementedError, 'Subclasses must implement description method'
      end

      def type
        'AND'
      end
    end
  end
end
