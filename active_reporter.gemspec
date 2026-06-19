$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_reporter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "active_reporter"
  spec.version     = ActiveReporter::VERSION
  spec.authors     = ["chaunce"]
  spec.email       = ["chaunce.slc@gmail.com"]
  spec.homepage    = "http://github.com/chaunce/active_reporter"
  spec.summary     = "Rails data aggregation framework"
  spec.description = "Flexible but opinionated framework for defining and running reports on Rails models backed by SQL databases."
  spec.license     = "MIT"

  spec.metadata = { rubygems_mfa_required: "true" }
  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.test_files = Dir["spec/**/*"]

  spec.add_dependency "rails", ">= 7.1", "< 9"
  spec.add_dependency "deeply_enumerable", "~> 2.0"
  spec.add_dependency "csv", "~> 3.3"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "ostruct"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-packaging"
  spec.add_development_dependency "rubocop-rspec"
end
