require 'active_record'

module Erbee
  class AssociationExplorer
    def initialize(model_name, depth: Erbee.configuration.depth)
      @model_name = model_name
      @depth = depth
      @visited = {}  # { model_class => current_depth }
      @results = []  # Array of ModelInfo
    end

    def explore
      start_model = model_class_for(@model_name)
      traverse(start_model, 0)
      @results
    end

    private

    def traverse(model_class, current_depth)
      return if current_depth > @depth
      return if @visited.key?(model_class) && @visited[model_class] <= current_depth

      @visited[model_class] = current_depth

      model_info = build_model_info(model_class)
      @results << model_info unless @results.any? { |m| m.model_class == model_class }

      model_class.reflect_on_all_associations.each do |assoc|
        next_model_class = assoc.klass
        traverse(next_model_class, current_depth + 1)
      end
    end

    def model_class_for(name)
      name.constantize
    end

    def build_model_info(model_class)
      associations = model_class.reflect_on_all_associations.map do |assoc|
        {
          name: assoc.name,
          type: assoc.macro,       # :belongs_to, :has_many, :has_one, etc.
          class_name: assoc.klass.name
        }
      end

      columns = model_class.columns.map do |col|
        { name: col.name, type: col.type, null: col.null }
      end

      ModelInfo.new(
        model_class: model_class,
        associations: associations,
        columns: columns
      )
    end
  end
end

