module Erbee
  class PolymorphicRegistry
    # The data structure is: { polymorphic_name => { association_name => [Array of owner class names] } }
    # For example: { "imageable" => { "images" => ["User", "Article"] } }
    # This holds the models that declare something like 'has_many :images, as: :imageable'.

    attr_reader :map

    def initialize
      # Initialize @map so that each key references a nested hash
      @map = Hash.new { |h, k| h[k] = {} }
    end

    # Register a has_many ... as: :polymorphic_name
    # For example, add("imageable", "images", "User") means:
    #  "User" has 'has_many :images, as: :imageable'
    def add(polymorphic_name, association_name, owner_class)
      @map[polymorphic_name][association_name] ||= []
      @map[polymorphic_name][association_name] << owner_class
    end

    # For example, if polymorphic_name = "imageable",
    # possible_owners("imageable") might return ["User", "Article", ...]
    # because each one has 'has_many :images, as: :imageable'.
    def possible_owners(polymorphic_name)
      # We gather all associated class arrays across the nested hash and flatten them:
      #   @map["imageable"].values.flatten.uniq
      @map[polymorphic_name].values.flatten.uniq
    end
  end
end
