require_relative "polymorphic_registry"

module Erbee
  class PolymorphicCollector
    def self.collect!
      # After eager_load! is called, we retrieve all models from ActiveRecord::Base.descendants.
      # Then we collect reverse-polymorphic associations (e.g., has_many :images, as: :imageable).
      registry = PolymorphicRegistry.new

      ActiveRecord::Base.descendants.each do |model|
        model.reflect_on_all_associations.each do |assoc|
          # Check if the macro is :has_many or :has_one and the :as option is present.
          # Example: has_many :images, as: :imageable
          next unless %i[has_many has_one].include?(assoc.macro) && assoc.options[:as].present?

          polymorphic_name = assoc.options[:as].to_s
          association_name = assoc.name.to_s  # e.g., "images"
          registry.add(polymorphic_name, association_name, model.name)
        end
      end

      registry
    end
  end
end
