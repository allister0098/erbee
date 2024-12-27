require 'ostruct'

module RandomModelInfoHelper
  # Generates an array of random ModelInfo objects with consistent associations
  def create_random_model_infos(table_count = 50, seed = 12345)
    # 1. Fix the seed to make randomness reproducible
    srand seed

    # 2. Generate table names: table01, table02, ..., table50
    table_names = (1..table_count).map { |i| "table%02d" % i }

    # 3. Initialize ModelInfo objects with random columns
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

    # 4. Assign consistent associations
    # To ensure consistency, we'll first assign belongs_to and has_many pairs
    # We'll iterate through the models and randomly assign associations ensuring consistency
    model_infos.each do |mi|
      # Each model can have 0 to 3 associations
      rand(0..3).times do
        # Choose association type
        assoc_type = random_assoc_type

        # Select a target model that is not the current model
        target = (model_infos - [mi]).sample
        next if target.nil?

        # Avoid duplicate associations
        existing_assoc = mi.associations.find { |a| a[:class_name] == target.model_class.name }
        next if existing_assoc

        # Assign association based on type
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