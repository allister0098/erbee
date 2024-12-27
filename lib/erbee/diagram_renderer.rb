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

      # Relationships
      visited_edges = {}
      @model_infos.each do |model_info|
        model_info.associations.each do |assoc|
          # Some associations may have an array of class_name if polymorphic => multiple owners
          class_names = assoc[:class_name].is_a?(Array) ? assoc[:class_name] : [assoc[:class_name]]

          class_names.each do |dst_class_name|
            if dst_class_name == "POLYMORPHIC"
              # We can either skip or draw a dummy node. Example: skip or draw a placeholder
              # Here we demonstrate a dummy edge:
              lines << "    #{draw_poly_dummy_edge(model_info, assoc)}"
              next
            end

            # Find the corresponding model info for dst_class_name
            dst_info = @model_infos.find { |mi| mi.model_class.name == dst_class_name }
            next unless dst_info

            src_table = model_info.model_class.table_name
            dst_table = dst_info.model_class.table_name

            # Avoid duplicates
            edge_key = [src_table, dst_table].sort.join("-")
            next if visited_edges[edge_key]
            visited_edges[edge_key] = true

            # Render the relationship
            relation_str = mermaid_relation(
              assoc[:type],             # e.g. :has_many or :belongs_to
              src_table,
              dst_table,
              assoc[:polymorphic]       # e.g. true or false
            )
            lines << "    #{relation_str}"
          end
        end
      end

      lines << "```"
      lines.join("\n")
    end

    # Build the table definition in Mermaid syntax
    def build_table_definition(model_info)
      table_name = model_info.model_class.table_name
      columns_def = model_info.columns.map do |col|
        # Convert col[:type] to Mermaid-like type
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

    # Provide relationship symbols in Mermaid's erDiagram
    # e.g. belongs_to -> N:1, has_many -> 1:N
    # If is_poly is true, we can optionally alter the notation
    def mermaid_relation(assoc_type, src_table, dst_table, is_poly)
      # assoc_type = :belongs_to / :has_many, is_poly = true/false
      case assoc_type
      when :belongs_to
        if is_poly
          "#{src_table} |{--|| #{dst_table} : \"N:1 (poly)\""
        else
          "#{src_table} |{--|| #{dst_table} : \"N:1\""
        end
      when :has_many
        if is_poly
          "#{src_table} ||--|{ #{dst_table} : \"1:N (poly)\""
        else
          "#{src_table} ||--|{ #{dst_table} : \"1:N\""
        end
      else
        # fallback -> 1:1
        "#{src_table} ||--|| #{dst_table} : \"1:1\""
      end
    end

    # Draw a dummy edge if class_name is "POLYMORPHIC"
    def draw_poly_dummy_edge(model_info, assoc)
      src_table = model_info.model_class.table_name
      # e.g. just show it as a special node
      # "image" -- "(poly: imageable)"
      %Q(#{src_table} -- "(poly:#{assoc[:name]})")
    end
  end
end
