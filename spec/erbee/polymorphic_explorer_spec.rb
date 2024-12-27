require "active_record"

RSpec.describe "Polymorphic relationships in Erbee" do
  before(:all) do
    # 1) Set up an in-memory SQLite database for testing
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

    # 2) Define the schema (tables)
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name
      end

      create_table :images, force: true do |t|
        t.string :file_path
        t.string :imageable_type
        t.integer :imageable_id
      end
    end

    # 3) Define models
    class User < ActiveRecord::Base
      has_many :images, as: :imageable
    end

    class Image < ActiveRecord::Base
      belongs_to :imageable, polymorphic: true
    end
  end

  after(:all) do
    # 4) Remove the defined classes to avoid conflicts in other tests
    Object.send(:remove_const, :User)
    Object.send(:remove_const, :Image)
  end

  it "User -> images is recognized as a reverse-polymorphic association" do
    # 1) Run the AssociationExplorer with 'User' as the starting model
    explorer = Erbee::AssociationExplorer.new("User", depth: 1)
    model_infos = explorer.explore

    # 2) Find the ModelInfo for the User class
    user_info = model_infos.find { |m| m.model_class.name == "User" }
    expect(user_info).not_to be_nil

    # 3) Check the :images association within User
    images_assoc = user_info.associations.find { |a| a[:name] == :images }
    expect(images_assoc).not_to be_nil, "Expected an association :images in User"

    # 4) Verify that this association is type: :has_many and marked as polymorphic
    expect(images_assoc[:type]).to eq(:has_many)
    expect(images_assoc[:polymorphic]).to eq(true), "Expected reverse-polymorphic to be true"

    # 5) Confirm that the class_name is "Image"
    #    (It could be an Array if multiple target classes are possible)
    if images_assoc[:class_name].is_a?(String)
      expect(images_assoc[:class_name]).to eq("Image")
    else
      expect(images_assoc[:class_name]).to include("Image")
    end
  end

  it "Image -> imageable is recognized as a polymorphic belongs_to" do
    # 1) Run the AssociationExplorer with 'Image' as the starting model
    explorer = Erbee::AssociationExplorer.new("Image", depth: 1)
    model_infos = explorer.explore

    # 2) Find the ModelInfo for the Image class
    image_info = model_infos.find { |m| m.model_class.name == "Image" }
    expect(image_info).not_to be_nil

    # 3) Search for the :imageable association in Image
    imageable_assoc = image_info.associations.find { |a| a[:name] == :imageable }
    expect(imageable_assoc).not_to be_nil

    # 4) Check that it's a belongs_to, polymorphic: true
    expect(imageable_assoc[:type]).to eq(:belongs_to)
    expect(imageable_assoc[:polymorphic]).to eq(true)
  end
end
