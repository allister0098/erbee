require "active_record"
require_relative "polymorphic_collector"

module Erbee
  class AssociationExplorer
    def initialize(model_name, depth: Erbee.configuration.depth)
      @model_name = model_name
      @depth = depth
      @visited = {}
      @results = []
      # We use an existing PolymorphicCollector to gather reverse-polymorphic associations.
      @polymorphic_registry = PolymorphicCollector.collect!
    end

    def explore
      start_model = model_class_for(@model_name)
      traverse(start_model, 0)
      @results
    end

    private

    def traverse(model_class, current_depth)
      return if current_depth > @depth
      # If we've already visited this model at an equal or lower depth, skip.
      return if @visited.key?(model_class) && @visited[model_class] <= current_depth

      @visited[model_class] = current_depth

      model_info = build_model_info(model_class)
      unless @results.any? { |m| m.model_class == model_class }
        @results << model_info
      end

      # Use the associations from model_info to recurse further
      model_info.associations.each do |assoc|
        next_class_names = assoc[:class_name].is_a?(Array) ? assoc[:class_name] : [assoc[:class_name]]
        next_class_names.each do |cn|
          next if cn == "POLYMORPHIC"

          begin
            next_model = cn.constantize
            traverse(next_model, current_depth + 1)
          rescue NameError
            # Skip if the class doesn't exist
          end
        end
      end
    end

    def model_class_for(name)
      name.constantize
    end

    def build_model_info(model_class)
      associations = model_class.reflect_on_all_associations.flat_map do |assoc|
        # 1) belongs_to with polymorphic: true
        if assoc.macro == :belongs_to && assoc.polymorphic?
          # Example: belongs_to :customer, polymorphic: true
          poly_name = assoc.name.to_s
          # The collector may return multiple owner classes if they all have has_many ... as: poly_name
          possible_owners = @polymorphic_registry.possible_owners(poly_name)
          if possible_owners.empty?
            # Fallback if no owners are found
            [{
               name: assoc.name,
               type: assoc.macro,            # e.g., :belongs_to
               polymorphic: true,
               class_name: "POLYMORPHIC"
             }]
          else
            possible_owners.map do |owner_class_name|
              {
                name: assoc.name,
                type: assoc.macro,
                polymorphic: true,
                class_name: owner_class_name
              }
            end
          end

          # 2) has_many (or has_one) with as: :xxx => reverse polymorphic
        elsif %i[has_many has_one].include?(assoc.macro) && assoc.options[:as].present?
          # Example: has_many :images, as: :imageable
          # Rails reflection returns assoc.polymorphic? == false, but we manually set polymorphic: true here
          [{
             name: assoc.name,
             type: assoc.macro,   # e.g., :has_many
             polymorphic: true,   # Reverse polymorphic side
             class_name: assoc.klass.name
           }]

        else
          # 3) Normal association
          [{
             name: assoc.name,
             type: assoc.macro,   # :belongs_to, :has_many, ...
             polymorphic: false,
             class_name: assoc.klass.name
           }]
        end
      end

      columns = model_class.columns.map do |col|
        { name: col.name, type: col.type, null: col.null }
      end

      # ModelInfo is initialized with keyword arguments
      ModelInfo.new(
        model_class:  model_class,
        associations: associations,
        columns:      columns
      )
    end
  end
end
