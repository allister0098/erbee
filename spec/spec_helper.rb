# frozen_string_literal: true

# spec/spec_helper.rb

require "bundler/setup"
require "erbee"            # Load the ERBee gem
require "active_record"    # Use ActiveRecord for testing
require "fileutils"

RSpec.configure do |config|
  # Common setup before the entire test suite
  config.before(:suite) do
    # Establish a connection to an in-memory SQLite3 DB for testing
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

    # Create tables (as an example, users and posts)
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name
      end

      create_table :posts, force: true do |t|
        t.string :title
        t.integer :user_id
      end
    end

    # Define test models
    class User < ActiveRecord::Base
      has_many :posts
    end

    class Post < ActiveRecord::Base
      belongs_to :user
    end
  end

  # Cleanup or additional tasks after the suite
  config.after(:suite) do
    # If you need any teardown logic, it can be added here
  end
end
