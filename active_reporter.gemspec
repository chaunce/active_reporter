$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_reporter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_reporter"
  s.version     = ActiveReporter::VERSION
  s.authors     = ["chaunce"]
  s.email       = ["chaunce.slc@gmail.com"]
  s.homepage    = "http://github.com/chaunce/active_reporter"
  s.summary     = "Rails data aggregation framework"
  s.description = "Flexible but opinionated framework for defining and running reports on Rails models backed by SQL databases."
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 6.1", "< 8"
  s.add_dependency "deeply_enumerable", ">= 0.9.3", "< 2.0"

  s.add_development_dependency "pg"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "pry"
  s.add_development_dependency "faker"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "byebug"
end
