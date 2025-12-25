# Guía de Instalación

## Requisitos Previos

Este proyecto requiere Ruby versión 2.7 o superior.

## Instalación de Ruby

### Windows

1. **Descargar RubyInstaller**:
   - Ve a https://rubyinstaller.org/
   - Descarga "Ruby+Devkit 3.2.X" (última versión estable)
   - Ejecuta el instalador
   - Asegúrate de marcar "Add Ruby executables to your PATH"

2. **Verificar la instalación**:
   ```bash
   ruby --version
   ```

### macOS

1. **Usando Homebrew** (recomendado):
   ```bash
   brew install ruby
   ```

2. **Verificar la instalación**:
   ```bash
   ruby --version
   ```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install ruby-full
```

## Configuración del Proyecto

1. **Navegar al directorio del proyecto**:
   ```bash
   cd "C:\Users\gerar\OneDrive\Escritorio\proyecto personales\legal atoms"
   ```

2. **Instalar Bundler** (si no está instalado):
   ```bash
   gem install bundler
   ```

3. **Instalar las dependencias del proyecto**:
   ```bash
   bundle install
   ```

## Ejecutar el Proyecto

Una vez instalado Ruby y las dependencias:

```bash
ruby questionnaire.rb --config config/personal_information.yaml,config/about_the_situation.yaml --responses config/user_response.yaml
```

## Ejecutar los Tests

```bash
bundle exec rspec
```

## Verificar que Ruby está instalado correctamente

```bash
ruby --version
gem --version
bundle --version
```

## Problemas Comunes

### "ruby: command not found"
- Ruby no está instalado o no está en el PATH
- Reinicia la terminal después de instalar Ruby
- En Windows, asegúrate de haber marcado "Add to PATH" durante la instalación

### "bundle: command not found"
- Bundler no está instalado
- Ejecuta: `gem install bundler`

### Errores de permisos en Linux/macOS
- Puede que necesites usar `sudo` para instalar gemas globalmente
- Considera usar un gestor de versiones de Ruby como rbenv o rvm

## Estructura del Proyecto

```
legal atoms/
├── lib/                    # Código fuente
├── spec/                   # Tests
├── config/                 # Archivos de configuración YAML
├── schema/                 # JSON Schema para validación
├── questionnaire.rb        # Script ejecutable principal
├── Gemfile                 # Dependencias del proyecto
└── README.md              # Documentación
```

## Siguiente Paso

Después de instalar Ruby y las dependencias, consulta el README.md para ver cómo usar el proyecto.
