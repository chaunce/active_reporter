module ActiveReporter
  class << self
    def database_type
      @database_type ||= case database_adapter
      when /postgres/ then :postgres
      when /mysql/ then :mysql
      when /sqlite/ then :sqlite
      else
        raise "unsupported database #{database_adapter}"
      end
    end

    def numeric?(value)
      value.is_a?(Numeric) || value.is_a?(String) && value =~ /\A\d+(?:\.\d+)?\z/
    end

    private

    def database_adapter
      @database_adapter ||= if ActiveRecord.gem_version < Gem::Version.new("6.1")
        ActiveRecord::Base.connection_config[:adapter]
      else
        ActiveRecord::Base.connection_db_config.adapter
      end
    end
  end
end

require "deeply_enumerable"
Dir.glob(File.join(__dir__, "active_reporter", "*/")).each { |file| require file.chomp("/") }
