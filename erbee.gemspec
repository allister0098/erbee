# frozen_string_literal: true

require_relative "lib/erbee/version"

Gem::Specification.new do |spec|
  spec.name = "erbee"
  spec.version = Erbee::VERSION
  spec.authors = ["allister0098"]

  spec.summary       = "Automatically generate ER diagrams for Rails applications using Mermaid."
  spec.description   = "Erbee is a Ruby gem designed to automatically generate Entity-Relationship (ER) diagrams for your Rails applications. Leveraging the power of Mermaid for visualization, Erbee provides an easy and flexible way to visualize your database schema and model associations directly from your Rails models."
  spec.homepage      = "https://github.com/allister0098/erbee"
  spec.email         = "taro0098egg@gmail.com"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
end
