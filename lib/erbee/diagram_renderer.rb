require 'securerandom'

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

    # Generates Mermaid syntax for ER Diagram
    def build_mermaid_er
      lines = []
      # Start of code block
      lines << "```mermaid"
      lines << "erDiagram"

      # Table definition section (TABLE { ... } )
      @model_infos.each do |model_info|
        lines << build_table_definition(model_info)
      end

      # Relationships (TABLE1 ||--|{ TABLE2 : "1:N" )
      visited_edges = {}
      @model_infos.each do |model_info|
        model_info.associations.each do |assoc|
          # Source and Destination table names
          src_table = model_info.model_class.table_name
          dst_info = @model_infos.find { |mi| mi.model_class.name == assoc[:class_name] }
          next unless dst_info

          dst_table = dst_info.model_class.table_name

          # Do not write duplicate edges that have been used once
          edge_key = [src_table, dst_table].sort.join("-")
          next if visited_edges[edge_key]
          visited_edges[edge_key] = true

          # Get relation symbol
          relation_str = mermaid_relation(assoc[:type], src_table, dst_table)
          lines << "    #{relation_str}"
        end
      end

      lines << "```"
      lines.join("\n")
    end

    # Table definition section
    # Example:
    # TableName {
    #    int id
    #    string name
    # }
    def build_table_definition(model_info)
      table_name = model_info.model_class.table_name
      columns_def = model_info.columns.map do |col|
        # e.g. "int id", "string name"
        # Example of slightly converting the type to resemble Mermaid:
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

    # Outputs symbols like 1:1 / 1:N / N:N based on the type of relationship
    # In Mermaid's erDiagram, you can use symbols like ||--|| for 1:1, ||--|{ for 1:N, }|--|{ for N:N, etc.
    # Example: "TABLE1 ||--|{ TABLE2 : "1:N""
    def mermaid_relation(assoc_type, src_table, dst_table)
      # Example of provisional mapping:
      # belongs_to → 1:1 (??) or "N:1", actual determination is a bit more complex
      # has_many → 1:N
      # has_one → 1:1
      # (many-to-many → has_and_belongs_to_many → N:N)
      # Here, simply:
      # belongs_to: src is N, dst is 1
      # has_many:   src is 1, dst is N
      # has_one:    src is 1, dst is 1
      # has_and_belongs_to_many: N:N
      # If unknown, treat as 1:1
      case assoc_type
      when :belongs_to
        # If "Post" belongs_to "User", then Post:User = N:1
        # => Post |{--|| User
        # (In Mermaid's erDiagram, "TABLE1 |{--|| TABLE2" means TABLE1:N, TABLE2:1)
        "#{src_table} |{--|| #{dst_table} : \"N:1\""
      when :has_many
        # "User" has_many "Posts" => User:Posts = 1:N
        # => User ||--|{ Post
        "#{src_table} ||--|{ #{dst_table} : \"1:N\""
      when :has_one
        # => 1:1
        "#{src_table} ||--|| #{dst_table} : \"1:1\""
      when :has_and_belongs_to_many
        # => N:N
        "#{src_table} }|--|{ #{dst_table} : \"N:N\""
      else
        # fallback -> 1:1
        "#{src_table} ||--|| #{dst_table} : \"1:1\""
      end
    end

    # Simple conversion of column types
    # If you have types like integer/string/datetime in SQLite, you can align with Mermaid's notation
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
