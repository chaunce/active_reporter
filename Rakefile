begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

require "rdoc/task"

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "ActiveReporter"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include("README.rdoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  ADAPTERS = %w[postgres mysql sqlite].freeze

  desc "Run the spec suite against every database adapter (#{ADAPTERS.join(", ")})"
  task :all do
    failed = []
    ADAPTERS.each do |db|
      puts "\n\e[1;34m== Running specs against #{db} ==\e[0m"
      ok = system({ "DB" => db }, "bundle", "exec", "rspec")
      failed << db unless ok
    end

    puts "\n\e[1m== Summary ==\e[0m"
    ADAPTERS.each do |db|
      status = failed.include?(db) ? "\e[31mFAILED\e[0m" : "\e[32mpassed\e[0m"
      puts "  #{db}: #{status}"
    end
    abort "\nSpecs failed for: #{failed.join(", ")}" unless failed.empty?
  end
end

task :default => "spec:all"
