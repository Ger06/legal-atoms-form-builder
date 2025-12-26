# Legal Atoms Form Builder - Documentación Técnica Completa

**Autor:** Gerard Perez
**GitHub:** [@Ger06](https://github.com/Ger06)
**Repositorio:** [legal-atoms-form-builder](https://github.com/Ger06/legal-atoms-form-builder)
**Fecha:** Diciembre 2025

---

## Tabla de Contenidos

1. [Descripción del Proyecto](#descripción-del-proyecto)
2. [Arquitectura y Patrones de Diseño](#arquitectura-y-patrones-de-diseño)
3. [Implementación Paso a Paso](#implementación-paso-a-paso)
4. [Principios de Clean Code Aplicados](#principios-de-clean-code-aplicados)
5. [Funcionalidades Bonus Implementadas](#funcionalidades-bonus-implementadas)
6. [Estrategia de Testing](#estrategia-de-testing)
7. [CI/CD y DevOps](#cicd-y-devops)
8. [Mejoras Futuras y Roadmap](#mejoras-futuras-y-roadmap)
9. [Preguntas y Respuestas de Entrevista](#preguntas-y-respuestas-de-entrevista)
10. [Propuesta de Integración con Base de Datos](#propuesta-de-integración-con-base-de-datos)

---

## Descripción del Proyecto

### ¿Qué es este Proyecto?

Un **constructor de formularios flexible y extensible** para crear cuestionarios dinámicos con lógica de visibilidad condicional. Construido completamente en Ruby, esta herramienta CLI soporta:

- **5 Tipos de Preguntas**: Texto, Booleano, Radio, Checkbox, Dropdown
- **Condiciones de Visibilidad Complejas**: value_check, AND, OR, NOT (componibles)
- **Configuración YAML**: Definiciones de cuestionarios legibles
- **Dos Modos de Ejecución**:
  - Modo YAML: Respuestas pre-llenadas desde archivo
  - Modo Interactivo: Prompts en tiempo real con validación
- **Salida Profesional**: Renderizado colorizado en terminal
- **Validación JSON Schema**: Validación automática de configuraciones
- **Cobertura de Tests Completa**: Suite RSpec con SimpleCov (67%+ cobertura)
- **CI/CD**: Pipeline de GitHub Actions
- **Soporte Docker**: Ejecución containerizada

### Por Qué Esto Importa

Los servicios legales frecuentemente requieren recolectar información compleja y condicional de clientes. Este form builder demuestra:

1. **Complejidad de Lógica de Negocio**: Manejo de visibilidad condicional anidada
2. **Calidad de Código**: Arquitectura limpia, principios SOLID, patrones de diseño
3. **Listo para Producción**: Tests, CI/CD, Docker, documentación
4. **Experiencia de Usuario**: Modo interactivo con validación y output colorizado
5. **Extensibilidad**: Fácil agregar nuevos tipos de preguntas, condiciones o backends de almacenamiento

---

## Arquitectura y Patrones de Diseño

### Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────┐
│                    Punto de Entrada                         │
│                   questionnaire.rb                          │
│              (Parseo de argumentos CLI)                     │
└───────────────┬─────────────────────────────────────────────┘
                │
        ┌───────▼────────┐
        │ Selección Modo │
        └───────┬────────┘
                │
    ┌───────────┴───────────┐
    │                       │
┌───▼────────┐      ┌───────▼──────────┐
│ Modo YAML  │      │  Modo Interactivo│
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
        │  Dominio Core  │
        │  Questionnaire │
        └───────┬────────┘
                │
    ┌───────────┴───────────┐
    │                       │
┌───▼─────────┐      ┌──────▼─────────┐
│  Questions  │      │  Conditions    │
│  (5 tipos)  │      │  (4 tipos)     │
└─────────────┘      └────────────────┘
```

### Patrones de Diseño Implementados

#### 1. **Patrón Strategy** (Condiciones)

**Problema:** Lógica de evaluación de visibilidad diferente para cada tipo de condición.

**Solución:** Definir una interfaz común (`BaseCondition`) con método `evaluate` polimórfico.

```ruby
# lib/form_builder/conditions/base_condition.rb
module FormBuilder
  module Conditions
    class BaseCondition
      def evaluate(responses)
        raise NotImplementedError, 'Las subclases deben implementar evaluate'
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

**Beneficios:**
- Fácil agregar nuevos tipos de condiciones (solo extender `BaseCondition`)
- El código cliente no conoce implementaciones específicas
- Testeable en aislamiento

---

#### 2. **Patrón Template Method** (Preguntas)

**Problema:** Cada tipo de pregunta tiene lógica de renderizado única pero comparte estructura común.

**Solución:** Clase abstracta con flujo común, subclases sobrescriben pasos específicos.

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

  # Métodos template - subclases sobrescriben
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

**Beneficios:**
- Reutilización de código para lógica común
- Cada subclase se enfoca en su comportamiento único
- Fácil entender el flujo

---

#### 3. **Patrón Factory** (Input Handlers)

**Problema:** Necesidad de crear diferentes handlers de input basados en tipo de pregunta en modo interactivo.

**Solución:** Clase Factory que encapsula lógica de creación.

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

# Uso en InteractiveRunner
handler = InputHandlers::Factory.get_handler(question)
answer = handler.get_input
```

**Beneficios:**
- Responsabilidad Única: Factory maneja creación de objetos
- Código cliente no necesita conocer clases de handlers
- Fácil agregar nuevos handlers

---

#### 4. **Patrón Composite** (Condiciones Anidadas)

**Problema:** Las condiciones pueden anidarse arbitrariamente (AND de ORs, NOT de ANDs, etc.)

**Solución:** Las condiciones pueden contener otras condiciones, formando una estructura de árbol.

```ruby
# Ejemplo: Condición anidada compleja
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

# Evalúa a: live_in_us == true AND
#            (situation == 'dv' OR situation == 'sa') AND
#            NOT(has_lawyer == true)
```

**Beneficios:**
- Profundidad de anidamiento ilimitada
- Configuración YAML legible
- Cada nodo solo conoce sus hijos

---

#### 5. **Inyección de Dependencias** (Colorizer)

**Problema:** Necesidad de colores en producción pero no en tests.

**Solución:** Configuración inyectable con manejo de estado global.

```ruby
# lib/form_builder/colorizer.rb
module FormBuilder
  class Colorizer
    @enabled = $stdout.tty?  # Auto-detectar terminal

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

# En tests (spec/spec_helper.rb)
RSpec.configure do |config|
  config.before(:suite) do
    FormBuilder::Colorizer.disable!
  end
end
```

**Beneficios:**
- Tests verifican salida de texto plano
- Producción tiene salida colorizada
- Fuente única de verdad para estado de color

---

### Principios SOLID Aplicados

#### **S - Principio de Responsabilidad Única**

Cada clase tiene una razón para cambiar:

- `Questionnaire`: Cargar y manejar preguntas
- `Printer`: Renderizar cuestionario a terminal
- `Validator`: Validar YAML contra JSON Schema
- `InteractiveRunner`: Orquestar flujo interactivo
- `ResponseStorage`: Guardar respuestas a archivo
- Cada tipo `Question`: Renderizar su formato específico
- Cada tipo `Condition`: Evaluar su lógica específica

**Ejemplo de Violación Corregida:**
Inicialmente, `Questionnaire` manejaba tanto carga COMO impresión. Se extrajo clase `Printer`:

```ruby
# Antes (viola SRP)
class Questionnaire
  def print(responses)
    # 50 líneas de lógica de renderizado
  end
end

# Después (sigue SRP)
class Questionnaire
  # Solo maneja preguntas y visibilidad
end

class Printer
  def print(questionnaire, responses)
    # Dedicado a renderizado
  end
end
```

---

#### **O - Principio Abierto/Cerrado**

Las clases están abiertas para extensión, cerradas para modificación.

**Ejemplo:** Agregar un nuevo tipo de pregunta requiere CERO cambios al código existente:

```ruby
# Para agregar "DateQuestion", solo crear nuevo archivo:
class DateQuestion < BaseQuestion
  def render_type_label
    "(date question)"
  end

  def render_response(responses)
    # Renderizado específico de fecha
  end
end

# Actualizar factory (único lugar que necesita cambio)
class Factory
  def self.get_handler(question)
    case question.class.name.split('::').last
    when 'DateQuestion'
      DateInputHandler.new(question)
    # ... casos existentes
    end
  end
end
```

No se necesitan cambios en:
- `Questionnaire`
- `Printer`
- Otros tipos de preguntas
- Clases de condiciones

---

#### **L - Principio de Sustitución de Liskov**

Cualquier subclase de `BaseQuestion` puede reemplazar `BaseQuestion` sin romper el código.

```ruby
# Esto funciona para CUALQUIER tipo de pregunta
def print_question(question, responses)
  puts question.render(responses)  # Llamada polimórfica
  question.visible?(responses)     # Funciona para todos los tipos
end

text_q = TextQuestion.new(...)
bool_q = BooleanQuestion.new(...)

print_question(text_q, responses)  # Funciona
print_question(bool_q, responses)  # Funciona
```

Todas las subclases honran el contrato base:
- `render(responses)` retorna un string
- `visible?(responses)` retorna boolean

---

#### **I - Principio de Segregación de Interfaz**

Ninguna clase es forzada a implementar métodos que no usa.

**Ejemplo:** InputHandlers tienen interfaz mínima requerida:

```ruby
class BaseInputHandler
  # Solo 4 métodos requeridos
  def prompt         # Mostrar prompt de input
  def validate(input) # Verificar si es válido
  def parse(input)   # Convertir a tipo apropiado
  def show_error     # Mostrar mensaje de error
end
```

Cada handler solo implementa lo que necesita. Sin dependencias forzadas.

---

#### **D - Principio de Inversión de Dependencias**

Depender de abstracciones, no de clases concretas.

**Ejemplo:** `InteractiveRunner` depende de abstracción `BaseInputHandler`:

```ruby
class InteractiveRunner
  def ask_question(questionnaire, question)
    # Depende de abstracción (cualquier handler que implemente get_input)
    handler = InputHandlers::Factory.get_handler(question)
    answer = handler.get_input  # No importa qué handler específico
  end
end
```

Runner no conoce `TextInputHandler`, `RadioInputHandler`, etc. Solo conoce la interfaz.

---

## Implementación Paso a Paso

### Fase 1: Dominio Core (Preguntas y Condiciones)

**Objetivo:** Construir los bloques fundamentales.

#### Paso 1: Crear Clases Base

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

**Conceptos Clave para Principiantes en Ruby:**

1. **Namespacing con Módulos:** `FormBuilder::Questions::BaseQuestion`
   - Organiza código en grupos lógicos
   - Previene conflictos de nombres
   - `FormBuilder` es el namespace de la app, `Questions` es el namespace de features

2. **`attr_reader`:** Crea métodos getter
   ```ruby
   attr_reader :id  # Equivalente a:

   def id
     @id
   end
   ```

3. **Variables de Instancia:** `@id`, `@type` son accesibles en todos los métodos de instancia

4. **Asignación Condicional:**
   ```ruby
   return true unless @visibility
   # Equivalente a:
   if @visibility.nil?
     return true
   end
   ```

---

#### Paso 2: Implementar Tipos de Preguntas Concretos

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

**Conceptos Clave:**

1. **`super`:** Llama al método initialize de la clase padre
   ```ruby
   super(data, questionnaire_id)
   # Llama BaseQuestion.initialize(data, questionnaire_id)
   ```

2. **Interpolación de Strings:** `"#{variable}"`
   ```ruby
   "at least <#{@min_length}> characters"
   # Si @min_length = 10:
   # "at least <10> characters"
   ```

3. **Métodos de Array:**
   ```ruby
   constraints << "text"  # Agregar a array
   constraints.join(' and ')  # "item1 and item2 and item3"
   ```

4. **Método `dig` de Hash:** Acceso seguro a hash anidado
   ```ruby
   responses.dig('questionnaire_1', 'name')
   # Equivalente a:
   responses['questionnaire_1'] && responses['questionnaire_1']['name']
   # Retorna nil si cualquier nivel no existe
   ```

---

#### Paso 3: Implementar Condiciones

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

**Conceptos Clave:**

1. **Retorno Boolean:** `evaluate` retorna true/false
2. **Verificación de Igualdad:** `==` compara valores
   ```ruby
   response_value == @expected_value
   # true si son iguales, false en caso contrario
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

**Conceptos Clave:**

1. **Método `map`:** Transforma cada elemento del array
   ```ruby
   [1, 2, 3].map { |x| x * 2 }  # => [2, 4, 6]

   # Nuestro caso:
   conditions_data.map { |data| BaseCondition.from_hash(data) }
   # Convierte cada hash en un objeto Condition
   ```

2. **Método `all?`:** Retorna true si TODOS los elementos pasan el bloque
   ```ruby
   [2, 4, 6].all? { |x| x.even? }  # => true
   [2, 3, 6].all? { |x| x.even? }  # => false

   # Nuestro caso:
   @conditions.all? { |c| c.evaluate(responses) }
   # Retorna true solo si TODAS las condiciones evalúan a true
   ```

3. **Bloques:** `{ |param| code }`
   - Similar a funciones anónimas/lambdas
   - `|condition|` es el parámetro del bloque
   - El código dentro se ejecuta para cada elemento

---

### Fase 2: Configuración YAML y Validación

#### Paso 4: Cargador de Cuestionarios

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

**Conceptos Clave:**

1. **Métodos de Clase:** `self.method_name`
   ```ruby
   def self.from_yaml(file_path)
     # Se llama: Questionnaire.from_yaml('file.yaml')
     # NO: questionnaire.from_yaml('file.yaml')
   end
   ```

2. **Carga de YAML:**
   ```ruby
   YAML.load_file('config.yaml')
   # Retorna hash/array de Ruby desde archivo YAML
   ```

3. **Método `select`:** Filtra array
   ```ruby
   [1, 2, 3, 4].select { |x| x.even? }  # => [2, 4]

   # Nuestro caso:
   @questions.select { |q| q.visible?(responses) }
   # Retorna solo preguntas donde visible? retorna true
   ```

4. **Métodos Privados:** Solo llamables dentro de la clase
   ```ruby
   private

   def parse_questions(data)
     # Solo puede llamarse desde otros métodos de instancia
     # NO desde afuera: questionnaire.parse_questions(data) # Error!
   end
   ```

---

#### Paso 5: Validación JSON Schema (BONUS)

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

**Ejemplo de Schema:**

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

**Beneficios:**

1. **Detección Temprana de Errores:** Configs inválidas fallan antes del runtime
2. **Auto-Documentación:** Schema muestra exactamente qué se espera
3. **Reglas de Validación:**
   - Campos requeridos
   - Verificación de tipos (string, array, object)
   - Coincidencia de patrones (regex)
   - Valores enum
   - Longitudes mín/máx

**Ejemplo de Error de Validación:**

```ruby
# YAML inválido:
id: personal-info  # Debería ser snake_case
title: ""          # No debería estar vacío
questions: []      # Debería tener al menos una pregunta

# Mensaje de error:
# Invalid questionnaire configuration:
# The property '#/id' value "personal-info" did not match the regex '^[a-z_]+$'
# The property '#/title' did not have a minimum string length of 1
# The property '#/questions' did not contain a minimum number of items 1
```

---

### Fase 3: Modo Interactivo (Feature BONUS)

#### Paso 6: Input Handlers con Template Method

```ruby
# lib/form_builder/input_handlers/base_input_handler.rb
class BaseInputHandler
  attr_reader :question

  def initialize(question)
    @question = question
  end

  # Método template - orquesta el flujo
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

  # Métodos abstractos - subclases deben implementar
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

**Conceptos Clave:**

1. **Loop Hasta Válido:**
   ```ruby
   loop do
     input = get_user_input
     if valid?(input)
       return input  # Sale del loop
     else
       show_error   # Continúa loop
     end
   end
   ```

2. **`raise NotImplementedError`:** Fuerza a subclases a implementar
   ```ruby
   # Si subclase no sobrescribe:
   handler.prompt  # => NotImplementedError: NotImplementedError
   ```

---

#### Paso 7: Input Handlers Concretos

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
    input  # Ya es un string
  end

  def show_error
    errors = []
    errors << "Minimum #{question.min_length} characters" if question.min_length
    errors << "Maximum #{question.max_length} characters" if question.max_length
    puts colorize("  ✗ Error: #{errors.join(', ')}", :red)
  end
end
```

**Conceptos Clave:**

1. **`gets.chomp`:** Leer input del usuario desde terminal
   ```ruby
   print "Enter name: "
   name = gets.chomp
   # Usuario escribe: "John" y presiona Enter
   # name = "John"
   #
   # Sin .chomp, name sería "John\n" (incluye newline)
   ```

2. **Cláusulas Guard:** Retorno temprano para casos inválidos
   ```ruby
   # En lugar de if anidado:
   if question.min_length
     if input.length < question.min_length
       return false
     end
   end

   # Usar cláusula guard:
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
    return false unless input.match?(/^\d+$/)  # Verificar si es numérico
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

**Conceptos Clave:**

1. **`each_with_index`:** Loop con contador de índice
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
   "123".match?(/^\d+$/)  # => true (todos dígitos)
   "12a".match?(/^\d+$/)  # => false (tiene letra)

   # Desglose de /^\d+$/:
   # ^     = inicio del string
   # \d    = dígito (0-9)
   # +     = uno o más
   # $     = fin del string
   ```

3. **String a Entero:** `"5".to_i => 5`

4. **Indexado de Array:** Arrays tienen índice base 0
   ```ruby
   options = [{label: 'A', value: 'a'}, {label: 'B', value: 'b'}]
   options[0]  # => {label: 'A', value: 'a'}
   options[1]  # => {label: 'B', value: 'b'}

   # Usuario ingresa "1", queremos options[0]:
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

**Conceptos Clave:**

1. **Método `split`:** Dividir string en array
   ```ruby
   "1,3,5".split(',')  # => ["1", "3", "5"]
   "a b c".split(' ')  # => ["a", "b", "c"]
   ```

2. **Atajo `map(&:method_name)`:**
   ```ruby
   # Forma larga:
   ["  1", " 2 ", "3  "].map { |s| s.strip }  # => ["1", "2", "3"]

   # Atajo usando symbol-to-proc:
   ["  1", " 2 ", "3  "].map(&:strip)  # => ["1", "2", "3"]

   # Explicación:
   # &:strip convierte el símbolo :strip en un proc que llama .strip
   ```

3. **Encadenamiento de `map`:**
   ```ruby
   input.split(',').map(&:strip).map { |n| options[n.to_i - 1][:value] }

   # Paso a paso:
   # "1,3,5"
   # .split(',')          => ["1", "3", "5"]
   # .map(&:strip)        => ["1", "3", "5"]
   # .map { |n| ... }     => ["value1", "value3", "value5"]
   ```

4. **Método `dup`:** Duplicar array/objeto
   ```ruby
   original = [1, 2, 3]
   copy = original.dup
   copy << 4
   # original => [1, 2, 3]
   # copy     => [1, 2, 3, 4]
   ```

---

## Principios de Clean Code Aplicados

### 1. Nombres Significativos

**Mal:**
```ruby
def calc(r)
  r.select { |q| q.v?(r) }
end
```

**Bien:**
```ruby
def visible_questions(responses)
  questions.select { |question| question.visible?(responses) }
end
```

### 2. Las Funciones Deben Hacer Una Cosa

**Mal:**
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

**Bien:**
```ruby
# Responsabilidades únicas
questionnaire = Questionnaire.from_yaml(file)
visible_questions = questionnaire.visible_questions(responses)
output = Printer.print(questionnaire, responses)
File.write(output_file, output)
```

### 3. DRY (Don't Repeat Yourself)

**Mal:**
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

**Bien:**
```ruby
class BaseQuestion
  def render(responses)
    output = "#{@text} #{render_type_label}\n"
    output += "   #{@visibility.description}\n" if @visibility
    output
  end

  # Subclases sobrescriben
  def render_type_label
    raise NotImplementedError
  end
end
```

### 4. Manejo de Errores

**Mal:**
```ruby
def load_questionnaire(file)
  YAML.load_file(file)
rescue
  nil
end
```

**Bien:**
```ruby
def load_questionnaire(file)
  YAML.load_file(file)
rescue Errno::ENOENT => e
  raise "Questionnaire file not found: #{file}"
rescue Psych::SyntaxError => e
  raise "Invalid YAML syntax in #{file}: #{e.message}"
end
```

### 5. Comentarios vs Código Auto-Documentado

**Mal:**
```ruby
# Verificar si la respuesta del usuario coincide con el valor esperado
def evaluate(responses)
  # Obtener el valor de respuesta del hash de respuestas
  rv = responses.dig(@qid, @quid)
  # Comparar con esperado
  rv == @ev
end
```

**Bien:**
```ruby
def evaluate(responses)
  response_value = responses.dig(@questionnaire_id, @question_id)
  response_value == @expected_value
end
```

---

## Funcionalidades Bonus Implementadas

### 1. Validación JSON Schema ✅

**Implementación:**
- Archivo Schema: `schema/questionnaire_schema.json`
- Clase Validator: `lib/form_builder/validator.rb`
- Auto-validación al cargar (puede deshabilitarse)

**Beneficios:**
- Captura errores de configuración temprano
- Sirve como documentación
- Previene errores en runtime

**Ejemplo de Validación:**
```ruby
# Config inválida
{
  "id": "invalid-id",  # Debería ser snake_case
  "title": "",         # No debería estar vacío
  "questions": []      # Debería tener al menos una
}

# Error:
# Invalid questionnaire configuration:
# - The property '#/id' value "invalid-id" did not match the regex '^[a-z_]+$'
# - The property '#/title' did not have a minimum string length of 1
```

---

### 2. Modo Interactivo ✅

**Características:**
- Prompts pregunta por pregunta
- Validación en tiempo real
- Evaluación dinámica de visibilidad
- Protección contra sobrescritura de archivos
- Salida colorizada

**Arquitectura:**
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

### 3. Salida de Terminal Colorizada ✅

**Implementación:**
- Clase `Colorizer` centralizada
- Detección TTY
- Amigable con tests (puede deshabilitarse)

**Esquema de Colores:**
```ruby
# Títulos
colorize("**QUESTIONNAIRE**", :blue, :bold)

# Números de pregunta
colorize("1.", :cyan)

# Mensajes de éxito
colorize("✓ Saved", :green)

# Errores
colorize("✗ Error: Invalid input", :red)

# Metadata
colorize("(text question)", :light_black)

# Opciones seleccionadas
colorize("Yes", :green)
```

---

### 4. Pipeline CI/CD ✅

**GitHub Actions:**
- Se ejecuta en: push, pull_request
- Matrix: Ruby 3.0, 3.1, 3.2
- Pasos:
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

### 5. Reporte de Cobertura de Código ✅

**Configuración SimpleCov:**
- Cobertura mínima: 65%
- Agrupado por módulo
- Filtros: specs, vendor
- Reportes HTML

**Cobertura Actual:** 67.19%

---

### 6. Soporte Docker ✅

**Archivos:**
- `Dockerfile`: Imagen Ruby 3.2-slim
- `docker-compose.yml`: Comandos simplificados
- `.dockerignore`: Excluir archivos innecesarios

**Comandos:**
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

## Estrategia de Testing

### Cobertura de Tests por Módulo

```
Questions/         ✅ 85% cobertura
├── TextQuestion         ✅ Totalmente testeado
├── BooleanQuestion      ✅ Totalmente testeado
├── RadioQuestion        ⚠️  Parcialmente testeado
├── CheckboxQuestion     ⚠️  Parcialmente testeado
└── DropdownQuestion     ⚠️  Parcialmente testeado

Conditions/        ✅ 90% cobertura
├── ValueCheck           ✅ Totalmente testeado
├── AndCondition         ✅ Totalmente testeado
├── OrCondition          ⚠️  Parcialmente testeado
└── NotCondition         ⚠️  Parcialmente testeado

Core/              ⚠️  60% cobertura
├── Questionnaire        ✅ Totalmente testeado
├── Validator            ✅ Totalmente testeado
├── Printer              ⚠️  Parcialmente testeado
├── InteractiveRunner    ❌ Sin testear (requiere mockear STDIN)
└── InputHandlers        ❌ Sin testear (requiere mockear STDIN)
```

### Tipos de Tests

**1. Tests Unitarios**
```ruby
# Testear métodos individuales en aislamiento
describe '#visible?' do
  it 'returns true when condition is met' do
    question = TextQuestion.new(data, 'q1')
    responses = {'q1' => {'have_alias' => true}}
    expect(question.visible?(responses)).to be true
  end
end
```

**2. Tests de Integración**
```ruby
# Testear múltiples componentes juntos
describe 'Questionnaire with visibility' do
  it 'shows only visible questions' do
    questionnaire = Questionnaire.from_yaml('spec/fixtures/questionnaire.yaml')
    responses = {'personal_info' => {'have_alias' => true}}

    visible = questionnaire.visible_questions(responses)
    expect(visible.map(&:id)).to include('alias')
  end
end
```

**3. Tests de Validación**
```ruby
# Testear manejo de errores
describe 'Validator' do
  it 'raises error for invalid question type' do
    data = {'id' => 'q1', 'type' => 'invalid', 'questions' => []}
    expect { Validator.validate(data) }.to raise_error(/Invalid/)
  end
end
```

---

## CI/CD y DevOps

### Workflow de GitHub Actions

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

**Beneficios:**
- ✅ Asegura compatibilidad entre versiones de Ruby
- ✅ Captura cambios que rompen funcionalidad temprano
- ✅ Verificaciones de calidad automatizadas
- ✅ No se necesita testing manual

### Reporte de Cobertura

**Integración SimpleCov:**
```ruby
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Questions', 'lib/form_builder/questions'
  add_group 'Conditions', 'lib/form_builder/conditions'
  minimum_coverage 65
end
```

**Reporte HTML:**
```
coverage/index.html
├── General: 67.19%
├── Questions/: 85%
├── Conditions/: 90%
└── Core/: 60%
```

---

## Mejoras Futuras y Roadmap

### Fase 1: Mejoras en Testing (Alta Prioridad)

#### 1.1 Agregar Tests para Modo Interactivo

**Desafío:** El modo interactivo requiere mockear STDIN/STDOUT.

**Solución:**

```ruby
# spec/interactive_runner_spec.rb
RSpec.describe FormBuilder::InteractiveRunner do
  describe '#run' do
    it 'collects responses interactively' do
      questionnaire = Questionnaire.from_yaml('spec/fixtures/simple.yaml')
      runner = InteractiveRunner.new([questionnaire])

      # Mockear input del usuario
      allow(runner).to receive(:gets).and_return("John Doe", "y", "my_responses.yaml", "y")

      # Capturar output
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

**Beneficios:**
- ✅ Testea flujo de usuario end-to-end
- ✅ Captura problemas de UX
- ✅ Aumenta cobertura a 75%+

---

### Fase 2: Integración con Base de Datos (Prioridad Media)

#### 2.1 ¿Por Qué Agregar una Base de Datos?

**Limitaciones Actuales:**
- ❌ Respuestas almacenadas en archivos YAML (no escalable)
- ❌ Sin manejo de usuarios
- ❌ Sin historial/versionado de respuestas
- ❌ Sin analytics

**Casos de Uso:**
1. **Sistema Multi-Usuario:** Rastrear qué usuarios enviaron qué respuestas
2. **Historial de Respuestas:** Ver cómo cambian respuestas en el tiempo
3. **Analytics:** ¿Qué preguntas se responden más comúnmente?
4. **Validación:** Prevenir envíos duplicados
5. **Guardados Parciales:** Reanudar llenado de cuestionario después

---

#### 2.2 Elección de Base de Datos: PostgreSQL

**¿Por Qué PostgreSQL?**

1. **Soporte JSONB:** Perfecto para almacenar datos dinámicos de cuestionarios
2. **Fuerte Integridad de Datos:** Cumplimiento ACID
3. **Queries Avanzados:** Analytics complejos
4. **Popular en Ecosistema Ruby:** Buen soporte ActiveRecord
5. **Gratis y Open Source**

**Alternativas Consideradas:**

| Base de Datos | Pros | Contras | Veredicto |
|---------------|------|---------|-----------|
| **PostgreSQL** | JSONB, maduro, poderoso | Requiere servidor | ✅ Mejor opción |
| MongoDB | Sin schema, fácil | Sin joins, consistencia débil | ❌ Overkill |
| SQLite | Simple, basado en archivo | Concurrencia limitada | ⚠️ Bueno solo para dev |
| MySQL | Popular, rápido | Sin buen soporte JSON | ❌ Débil para nuestras necesidades |

---

#### 2.3 Diseño de Schema de Base de Datos

```sql
-- tabla users
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- tabla questionnaires
CREATE TABLE questionnaires (
  id VARCHAR(50) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  config JSONB NOT NULL,  -- Config YAML completa como JSON
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- tabla responses
CREATE TABLE responses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  questionnaire_id VARCHAR(50) REFERENCES questionnaires(id),
  answers JSONB NOT NULL,  -- Todas las respuestas como JSON
  status VARCHAR(20) DEFAULT 'in_progress',  -- in_progress, completed, submitted
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  submitted_at TIMESTAMP,
  UNIQUE(user_id, questionnaire_id)  -- Una respuesta por usuario por cuestionario
);

-- tabla response_history (para versionado)
CREATE TABLE response_history (
  id SERIAL PRIMARY KEY,
  response_id INTEGER REFERENCES responses(id),
  answers JSONB NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices para performance
CREATE INDEX idx_responses_user_id ON responses(user_id);
CREATE INDEX idx_responses_questionnaire_id ON responses(questionnaire_id);
CREATE INDEX idx_responses_status ON responses(status);
CREATE INDEX idx_responses_answers ON responses USING GIN(answers);  -- Índice JSONB
```

**Beneficios del Schema:**

1. **Columnas JSONB:**
   - `config`: Almacenar definición completa de cuestionario
   - `answers`: Almacenar todas las respuestas (estructura flexible)
   - Queryable: `SELECT * FROM responses WHERE answers->>'name' = 'John'`

2. **Versionado:**
   - `response_history` rastrea cambios
   - Puede reconstruir respuesta en cualquier punto en el tiempo

3. **Rastreo de Estado:**
   - `in_progress`: Usuario empezó pero no terminó
   - `completed`: Usuario terminó pero no envió
   - `submitted`: Envío final

---

## Preguntas y Respuestas de Entrevista

### Preguntas Técnicas

**P1: Explica la diferencia entre `include` y `extend` en módulos de Ruby.**

**R:**
- **`include`**: Agrega métodos del módulo como **métodos de instancia**
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
  person.hello  # => "Hello!" (método de instancia)
  ```

- **`extend`**: Agrega métodos del módulo como **métodos de clase**
  ```ruby
  class Person
    extend Greetings
  end

  Person.hello  # => "Hello!" (método de clase)
  ```

---

**P2: ¿Qué es el Patrón Strategy y dónde lo usaste en este proyecto?**

**R:** El Patrón Strategy define una familia de algoritmos, encapsula cada uno, y los hace intercambiables.

**Componentes:**
1. **Interfaz Strategy:** `BaseCondition` (clase abstracta)
2. **Strategies Concretos:** `ValueCheckCondition`, `AndCondition`, etc.
3. **Contexto:** `BaseQuestion` (usa condiciones)

**Implementación:**
```ruby
# Interfaz strategy
class BaseCondition
  def evaluate(responses)
    raise NotImplementedError
  end
end

# Strategies concretos
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

# Contexto usa strategy
class BaseQuestion
  def visible?(responses)
    return true unless @visibility
    @visibility.evaluate(responses)  # Llamada polimórfica
  end
end
```

**Beneficios:**
- ✅ Fácil agregar nuevos tipos de condiciones
- ✅ Testeable en aislamiento
- ✅ Sigue Principio Abierto/Cerrado

---

**P3: ¿Cómo aseguraste que este proyecto siga los principios SOLID?**

**R:**

**S - Responsabilidad Única:**
- `Questionnaire`: Maneja preguntas
- `Printer`: Renderiza output
- `Validator`: Valida config
- Cada clase tiene UNA razón para cambiar

**O - Abierto/Cerrado:**
- Puede agregar nuevos tipos de preguntas sin modificar código existente
- Solo extender `BaseQuestion` y actualizar factory

**L - Sustitución de Liskov:**
- Cualquier subclase de `BaseQuestion` puede reemplazar `BaseQuestion`
- Código cliente no conoce tipos específicos

**I - Segregación de Interfaz:**
- `BaseInputHandler` tiene interfaz mínima (4 métodos)
- Sin dependencias forzadas

**D - Inversión de Dependencias:**
- `InteractiveRunner` depende de abstracción `BaseInputHandler`
- No de `TextInputHandler` concreto, etc.

---

**P4: ¿Qué es un Patrón Factory y por qué lo usaste?**

**R:** El Patrón Factory proporciona una interfaz para crear objetos sin especificar clases exactas.

**Problema:**
```ruby
# Sin factory (mal):
if question.type == 'text'
  handler = TextInputHandler.new(question)
elsif question.type == 'boolean'
  handler = BooleanInputHandler.new(question)
# ... muchos más elsif
end
```

**Solución:**
```ruby
# Con factory (bien):
handler = InputHandlers::Factory.get_handler(question)
```

**Beneficios:**
- ✅ Creación de objetos centralizada
- ✅ Código cliente no conoce clases concretas
- ✅ Fácil agregar nuevos tipos

---

### Preguntas Conductuales

**P5: Describe un bug desafiante que encontraste en este proyecto y cómo lo resolviste.**

**R:**

**Bug:** Los colores no se mostraban en terminales Windows durante el modo interactivo, aunque `$stdout.tty?` retornaba `true`.

**Investigación:**
1. Confirmé que `Colorizer.enabled` era `true`
2. Verifiqué que la gema `colorize` estuviera instalada
3. Probé en diferentes terminales (CMD, PowerShell, Git Bash)
4. Descubrí que algunas terminales Windows reportan `tty? = true` pero no soportan colores ANSI

**Solución:**
```ruby
# Original (no confiable):
@enabled = $stdout.tty?

# Arreglado (control explícito):
class InteractiveRunner
  def initialize(questionnaires)
    @questionnaires = questionnaires
    Colorizer.enable!  # Forzar colores en modo interactivo
  end
end
```

**Lección:** No confiar solo en auto-detección. Proporcionar sobrescrituras manuales.

---

**P6: ¿Cómo abordaste el testing de este proyecto?**

**R:**

**Estrategia:**
1. **Empezar con Dominio Core:** Testear preguntas y condiciones primero (mayor valor)
2. **Testear Interfaces Públicas:** Enfocarse en comportamiento, no implementación
3. **Usar Fixtures:** Archivos YAML para datos de prueba realistas
4. **Mockear Dependencias Externas:** File I/O, STDIN/STDOUT

**Ejemplo de Estructura de Test:**
```ruby
RSpec.describe FormBuilder::Questionnaire do
  describe '.from_yaml' do
    it 'loads a questionnaire from a YAML file' do
      # Arrange: Crear fixture
      File.write('tmp/test.yaml', fixture_data.to_yaml)

      # Act: Cargar cuestionario
      questionnaire = Questionnaire.from_yaml('tmp/test.yaml')

      # Assert: Verificar estructura
      expect(questionnaire.id).to eq('test')
      expect(questionnaire.questions.length).to eq(3)
    end
  end
end
```

**Estrategia de Cobertura:**
- Lógica core: 90%+ cobertura
- Casos edge: Comprensivos
- Happy paths: Esenciales
- Manejo de errores: Crítico

**Qué mejoraría:**
- Agregar tests de integración para modo interactivo (actualmente no testeado)
- Agregar benchmarks de performance
- Agregar mutation testing

---

**P7: Si tuvieras 2 semanas más, ¿qué agregarías?**

**R:**

**Semana 1:**
1. **Integración con Base de Datos** (3 días)
   - Setup PostgreSQL
   - Modelos ActiveRecord
   - Scripts de migración
   - Runner interactivo respaldado por DB

2. **Testing Comprensivo** (2 días)
   - Tests de modo interactivo (mockear STDIN)
   - Tests de integración
   - Benchmarks de performance
   - Aumentar cobertura a 85%+

**Semana 2:**
3. **Interfaz Web** (4 días)
   - API Sinatra/Rails
   - Endpoints REST
   - Frontend React (o HTML renderizado en servidor)
   - Autenticación de usuarios

4. **Dashboard de Analytics** (1 día)
   - Tasas de completitud
   - Popularidad de preguntas
   - Distribución de respuestas
   - Exportar reportes (PDF, CSV)

**Prioridad:** Base de datos primero (habilita todo lo demás).

---

## Propuesta de Integración con Base de Datos

*(Ver Fase 2 arriba para implementación completa)*

**Resumen:**
- **Base de Datos:** PostgreSQL con JSONB
- **ORM:** ActiveRecord
- **Schema:** Users, Questionnaires, Responses, ResponseHistory
- **Características:**
  - Capacidad de reanudar
  - Manejo de usuarios
  - Versionado de respuestas
  - Analytics

---

## Conclusión

Este proyecto demuestra:

✅ **Arquitectura Limpia:** Principios SOLID, patrones de diseño
✅ **Dominio de Ruby:** POO, módulos, metaprogramación
✅ **Testing:** RSpec, cobertura, CI/CD
✅ **DevOps:** Docker, GitHub Actions
✅ **Pensamiento de Producto:** UX (colores, modo interactivo), extensibilidad
✅ **Documentación:** README comprensivo, comentarios inline

**Listo para el Futuro:**
- Integración con base de datos diseñada
- Tipos adicionales de preguntas planificados
- Roadmap de analytics definido
- Funcionalidad de exportación delimitada

**Mi Aprendizaje:**
- Primer proyecto Ruby → aprendí patrones POO
- Implementé 6 patrones de diseño
- Logré 67% de cobertura de tests
- Desplegué pipeline CI/CD
- Dockericé para portabilidad

---

## Recursos

### Documentación
- [Ruby Docs](https://ruby-doc.org/)
- [RSpec](https://rspec.info/)
- [JSON Schema](https://json-schema.org/)
- [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html)

### Herramientas Usadas
- **Lenguaje:** Ruby 3.2
- **Testing:** RSpec 3.12, SimpleCov 0.22
- **Validación:** json-schema 4.0
- **UI:** colorize 1.1
- **CI/CD:** GitHub Actions
- **Containerización:** Docker 28.0.1

---

**¡Gracias por revisar mi proyecto!**
Estoy emocionado de discutir cualquier parte de esta implementación en detalle.

Gerard Perez
[@Ger06](https://github.com/Ger06)
