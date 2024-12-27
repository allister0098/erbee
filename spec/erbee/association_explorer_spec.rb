RSpec.describe Erbee::AssociationExplorer do
  describe "#explore" do
    it "collects the correct association info for the User model" do
      explorer = Erbee::AssociationExplorer.new("User", depth: 1)
      results = explorer.explore

      # User / Post models should be included in the results
      expect(results.map { |r| r.model_class.name }).to include("User", "Post")

      user_info = results.find { |r| r.model_class.name == "User" }
      post_info = results.find { |r| r.model_class.name == "Post" }

      # Check that User has columns such as 'id', 'name', 'created_at', 'updated_at'
      user_column_names = user_info.columns.map { |c| c[:name] }
      expect(user_column_names).to include("id", "name")

      # Check that User has has_many :posts
      user_assoc = user_info.associations.find { |a| a[:class_name] == "Post" }
      expect(user_assoc).not_to be_nil
      expect(user_assoc[:type]).to eq(:has_many)

      # Check that Post has columns such as 'id', 'title', 'user_id'
      post_column_names = post_info.columns.map { |c| c[:name] }
      expect(post_column_names).to include("id", "title", "user_id")

      # Check that Post has belongs_to :user
      post_assoc = post_info.associations.find { |a| a[:class_name] == "User" }
      expect(post_assoc).not_to be_nil
      expect(post_assoc[:type]).to eq(:belongs_to)
    end
  end
end

