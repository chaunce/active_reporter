# Configure Rails Environment
ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"

  add_group "Report", [
    "lib/active_reporter.rb",
    "lib/active_reporter/report",
    "lib/active_reporter/invalid_params_error.rb",
    "lib/active_reporter/version.rb",
  ]
  add_group "Aggregators", "lib/active_reporter/aggregator"
  add_group "Calculators", "lib/active_reporter/calculator"
  add_group "Trackers", "lib/active_reporter/tracker"
  add_group "Dimensions", "lib/active_reporter/dimension"
  add_group "Serializers", "lib/active_reporter/serializer"
  add_group "Tasks", "lib/active_reporter/tasks"
  add_group "Long files" do |src_file| src_file.lines.count > 100 end
  add_group "Short files" do |src_file| src_file.lines.count < 5 end
end

require File.expand_path("../../spec/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../spec/dummy/db/migrate", __FILE__)]

# Ensure the test database exists and its schema matches db/schema.rb, so the
# suite can run without a manual `rake db:create db:schema:load` step. If the
# database doesn't exist yet, create it and retry the schema check.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::NoDatabaseError
  ActiveRecord::Tasks::DatabaseTasks.create_current("test")
  retry
end

require "rails/test_help"
require "rspec/rails"
require "factory_bot_rails"
require "pry"
require "byebug"
require "ostruct"

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
end
