# Erbee

Erbee is a Ruby gem designed to automatically generate Entity-Relationship (ER) diagrams for your Rails applications. Leveraging the power of [Mermaid](https://mermaid-js.github.io/) for visualization, Erbee provides an easy and flexible way to visualize your database schema and model associations directly from your Rails models.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
    - [Generating ER Diagrams](#generating-er-diagrams)
    - [Output Options](#output-options)
- [Testing](#testing)
    - [Local File Output Test](#local-file-output-test)
    - [Tempfile Output Test](#tempfile-output-test)
- [Examples](#examples)
    - [Sample ER Diagram](#sample-er-diagram)

## Features

- **Automatic ER Diagram Generation**: Generate ER diagrams based on your Rails models and their associations.
- **Mermaid Integration**: Utilize Mermaid's `erDiagram` syntax for clear and interactive diagrams.
- **Flexible Output Options**: Output diagrams to local Markdown files or temporary files for testing purposes.
- **Customizable Configuration**: Easily configure output paths and generation settings.
- **Comprehensive Testing**: Includes tests for generating large ER diagrams with up to 50 tables and random relationships.

## Installation

Add Erbee to your application's Gemfile:

```ruby
gem 'erbee'
```

And then execute:

```bash
bundle install
```
Or install it yourself as:

```ruby
gem install erbee
```

## Configuration
Erbee can be configured to specify output paths and other settings. You can configure Erbee in an initializer or directly within your Ruby scripts.

### Example Configuration

```ruby
Erbee.configure do |config|
  config.output_path = "path/to/your/erdiagram.md" # Specify your desired output path
  config.depth = 2 # Specify the depth for association exploration (optional)
end
```

## Usage
Erbee provides a straightforward interface to generate ER diagrams from your Rails models.

### Generating ER Diagrams
You can generate an ER diagram by invoking the `DiagramRenderer` with your model information.

#### Example:
```ruby
# lib/erbee/diagram_renderer.rb
require 'erbee/model_info'
require 'ostruct'

module Erbee
  class DiagramRenderer
    def initialize(model_infos)
      @model_infos = model_infos
      @output_path = Erbee.configuration.output_path
    end

    def render
      mermaid_code = build_mermaid_er
      File.write(@output_path, mermaid_code)
      puts "Generated ER diagram (Mermaid erDiagram) at: #{@output_path}"
    end

    private

    # Generates Mermaid erDiagram syntax
    def build_mermaid_er
      lines = []
      lines << "```mermaid"
      lines << "erDiagram"

      # Table Definitions
      @model_infos.each do |model_info|
        lines << build_table_definition(model_info)
      end

      # Relationships
      visited_edges = {}
      @model_infos.each do |model_info|
        model_info.associations.each do |assoc|
          src_table = model_info.model_class.table_name
          dst_info = @model_infos.find { |mi| mi.model_class.name == assoc[:class_name] }
          next unless dst_info

          dst_table = dst_info.model_class.table_name

          edge_key = [src_table, dst_table].sort.join("-")
          next if visited_edges[edge_key]

          visited_edges[edge_key] = true

          relation_str = mermaid_relation(assoc[:type], src_table, dst_table)
          lines << "    #{relation_str}"
        end
      end

      lines << "```"
      lines.join("\n")
    end

    # Builds table definition in Mermaid syntax
    def build_table_definition(model_info)
      table_name = model_info.model_class.table_name
      columns_def = model_info.columns.map do |col|
        "#{mermaid_type(col[:type])} #{col[:name]}"
      end

      definition_lines = []
      definition_lines << "    #{table_name} {"
      columns_def.each do |c|
        definition_lines << "        #{c}"
      end
      definition_lines << "    }"
      definition_lines.join("\n")
    end

    # Defines relationships based on association type
    def mermaid_relation(assoc_type, src_table, dst_table)
      case assoc_type
      when :belongs_to
        "#{src_table} |{--|| #{dst_table} : \"N:1\""
      when :has_many
        "#{src_table} ||--|{ #{dst_table} : \"1:N\""
      when :has_one
        "#{src_table} ||--|| #{dst_table} : \"1:1\""
      when :has_and_belongs_to_many
        "#{src_table} }|--|{ #{dst_table} : \"N:N\""
      else
        "#{src_table} ||--|| #{dst_table} : \"1:1\""
      end
    end

    # Converts Rails column types to Mermaid types
    def mermaid_type(col_type)
      case col_type
      when :integer
        "int"
      when :float, :decimal
        "float"
      when :datetime, :date, :time, :timestamp
        "datetime"
      when :boolean
        "boolean"
      else
        "string"
      end
    end
  end
end
```

### Output Options
Erbee allows you to output the generated ER diagram to either a local Markdown file or a temporary file for testing.

####  Local File Output
Configure Erbee to output to a specific file path:

```ruby
Erbee.configure do |config|
  config.output_path = "spec/output/erdiagram.md"
end

model_infos = Erbee::AssociationExplorer.new("User", depth: 2).explore
renderer = Erbee::DiagramRenderer.new(model_infos)
renderer.render
```

#### Temporary File Output (For Testing)
For testing purposes, you can use Ruby's Tempfile to generate a temporary file that gets deleted after use.

```ruby
require "tempfile"

tmpfile = Tempfile.new(["erdiagram", ".md"])
Erbee.configure do |config|
  config.output_path = tmpfile.path
end

model_infos = Erbee::AssociationExplorer.new("User", depth: 2).explore
renderer = Erbee::DiagramRenderer.new(model_infos)
renderer.render

# After testing
tmpfile.close
tmpfile.unlink
```

### Testing
Erbee includes comprehensive tests to ensure the reliability of ER diagram generation, even with large and complex schemas.

#### Setting Up Tests
Ensure that you have RSpec installed and properly configured in your project. Erbee's tests include helpers for generating random model data.

##### Random Model Info Helper
Create a helper to generate random model information for testing.

```ruby
# spec/support/random_model_info_helper.rb
require 'ostruct'

module RandomModelInfoHelper
  # Generates an array of random ModelInfo objects with consistent associations
  def create_random_model_infos(table_count = 50, seed = 12345)
    # Fix the random seed for reproducibility
    srand seed

    # Generate table names: table01, table02, ..., table50
    table_names = (1..table_count).map { |i| "table%02d" % i }

    # Initialize ModelInfo objects with random columns
    model_infos = table_names.map do |tname|
      # Randomly assign 2 to 5 columns
      col_count = rand(2..5)
      columns = col_count.times.map do |i|
        {
          name: "col#{('A'.ord + i).chr}",  # colA, colB, etc.
          type: random_type,                # :integer, :string, etc.
          null: [true, false].sample
        }
      end

      # Initialize associations empty, to be filled later
      associations = []

      # Create a fake model_class object with name and table_name
      fake_class = OpenStruct.new(
        name: tname.capitalize,  # e.g., "Table01"
        table_name: tname        # e.g., "table01"
      )

      Erbee::ModelInfo.new(
        model_class:  fake_class,
        associations: associations,
        columns:      columns
      )
    end

    # Assign consistent associations
    model_infos.each do |mi|
      rand(0..3).times do
        assoc_type = random_assoc_type
        target = (model_infos - [mi]).sample
        next if target.nil?

        # Avoid duplicate associations
        existing_assoc = mi.associations.find { |a| a[:class_name] == target.model_class.name }
        next if existing_assoc

        case assoc_type
        when :belongs_to
          # Current model belongs_to target
          mi.associations << {
            name:       "#{target.model_class.table_name}_ref".to_sym,
            type:       :belongs_to,
            class_name: target.model_class.name
          }

          # Ensure target has has_many for current model
          target.associations << {
            name:       "#{mi.model_class.table_name}_collection".to_sym,
            type:       :has_many,
            class_name: mi.model_class.name
          }
        when :has_one
          # Current model has_one target
          mi.associations << {
            name:       "#{target.model_class.table_name}_ref".to_sym,
            type:       :has_one,
            class_name: target.model_class.name
          }

          # Ensure target has belongs_to for current model
          target.associations << {
            name:       "#{mi.model_class.table_name}_ref".to_sym,
            type:       :belongs_to,
            class_name: mi.model_class.name
          }
        when :has_many, :has_and_belongs_to_many
          # Current model has_many or has_and_belongs_to_many target
          mi.associations << {
            name:       "#{target.model_class.table_name}_collection".to_sym,
            type:       assoc_type,
            class_name: target.model_class.name
          }

          # Ensure target has belongs_to or has_and_belongs_to_many for current model
          inverse_type = assoc_type == :has_many ? :belongs_to : :has_and_belongs_to_many
          target.associations << {
            name:       "#{mi.model_class.table_name}_ref".to_sym,
            type:       inverse_type,
            class_name: mi.model_class.name
          }
        end
      end
    end

    model_infos
  end

  private

  # Returns a random column type
  def random_type
    [:integer, :string, :datetime, :boolean].sample
  end

  # Returns a random association type
  def random_assoc_type
    [:belongs_to, :has_many, :has_one, :has_and_belongs_to_many].sample
  end
end
```

#### RSpec Configuration
Ensure that the spec/support directory is loaded by RSpec by adding the following to your spec/spec_helper.rb or spec/rails_helper.rb:

```ruby
# spec/spec_helper.rb or spec/rails_helper.rb

RSpec.configure do |config|
  # Load support files
  Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

  # Other configurations...
end
```

### Local File Output Test
This test generates a Mermaid erDiagram with 50 random tables and relationships, saving the output to a local file for manual inspection.

```ruby
# spec/erbee/diagram_renderer_large_spec.rb
require "spec_helper"
require "fileutils"

RSpec.describe Erbee::DiagramRenderer do
  include RandomModelInfoHelper

  it "generates a Mermaid erDiagram for 50 random tables, saved locally" do
    # 1. Generate random ModelInfo array with fixed seed
    model_infos = create_random_model_infos(50, seed = 12345)

    # 2. Define output path (e.g., spec/output/random_erdiagram.md)
    output_dir = "spec/output"
    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
    local_md_path = File.join(output_dir, "random_erdiagram.md")

    # 3. Configure Erbee to output to the local file
    Erbee.configure do |config|
      config.output_path = local_md_path
    end

    # 4. Render the diagram
    renderer = Erbee::DiagramRenderer.new(model_infos)
    renderer.render

    # 5. Assertions
    expect(File).to exist(local_md_path)
    content = File.read(local_md_path)

    # Check that the content includes the Mermaid code block and 'erDiagram'
    expect(content).to include("```mermaid")
    expect(content).to include("erDiagram")

    # Check that some table definitions are present
    expect(content).to include("table01 {")
    expect(content).to include("table50 {")

    # Check that relationships are defined
    # Example: "table01 ||--|{ table02 : "1:N""
    expect(content).to match(/table\d{2}\s+\|\|--\|\{\s+table\d{2}/)

    # Output the path for manual inspection
    puts "Generated ER diagram saved at: #{local_md_path}"

    # Do not delete the file for manual inspection
  end
end
```

### Tempfile Output Test
This test generates a Mermaid erDiagram with 50 random tables and relationships, saving the output to a temporary file that gets deleted after the test.

```ruby
# spec/erbee/diagram_renderer_tempfile_spec.rb
require "spec_helper"
require "tempfile"

RSpec.describe Erbee::DiagramRenderer do
  include RandomModelInfoHelper

  it "generates a Mermaid erDiagram for 50 random tables using Tempfile and deletes it after" do
    # 1. Generate random ModelInfo array with fixed seed
    model_infos = create_random_model_infos(50, seed = 12345)

    # 2. Create a Tempfile for output
    tmpfile = Tempfile.new(["random_erdiagram", ".md"])

    # 3. Configure Erbee to output to the Tempfile
    Erbee.configure do |config|
      config.output_path = tmpfile.path
    end

    # 4. Render the diagram
    renderer = Erbee::DiagramRenderer.new(model_infos)
    renderer.render

    # 5. Assertions
    expect(File).to exist(tmpfile.path)
    content = File.read(tmpfile.path)

    # Check that the content includes the Mermaid code block and 'erDiagram'
    expect(content).to include("```mermaid")
    expect(content).to include("erDiagram")

    # Check that some table definitions are present
    expect(content).to include("table01 {")
    expect(content).to include("table50 {")

    # Check that relationships are defined
    # Example: "table01 ||--|{ table02 : "1:N""
    expect(content).to match(/table\d{2}\s+\|\|--\|\{\s+table\d{2}/)

    # Output the path for debugging (file will be deleted)
    puts "Generated ER diagram saved at: #{tmpfile.path}"

    # 6. Cleanup: close and delete the Tempfile
    tmpfile.close
    tmpfile.unlink  # This deletes the file
  end
end
```

## Examples
### Sample ER Diagram
Here's an example of how a generated ER diagram might look in Markdown using Mermaid's erDiagram syntax:

```merkdown
erDiagram
    users {
        int id
        string name
    }
    posts {
        int id
        string title
        int user_id
    }
    users ||--|{ posts : "1:N"
```

When rendered with a Mermaid-compatible viewer, this will display an ER diagram showing a one-to-many relationship between `users` and `posts`.
