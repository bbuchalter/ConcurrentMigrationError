# frozen_string_literal: true

begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  #gem "rails", github: "rails/rails"
  gem "activerecord", "5.2.1"
  gem "mysql2"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
@dbconfig = YAML.load(File.read('database.yml'))
ActiveRecord::Base.establish_connection(@dbconfig["test"])
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
end

class BugTest < Minitest::Test
  def test_lock_not_aquired_when_no_migrations_needed
    assert ActiveRecord::Base.connection.supports_advisory_locks?

    hold_advisory_lock_in_different_session do
      # This should not attempt to acquire a lock
      # because there are no migrations to run.
      err = assert_raises { empty_migration.migrate }
      assert_equal ActiveRecord::ConcurrentMigrationError, err.class

      assert_nil non_locking_empty_migration.migrate
    end
  end

  def hold_advisory_lock_in_different_session
    conn = new_mysql_connection
    conn.query("SELECT GET_LOCK('#{lock_id}', 0)")
    yield
  end

  def new_mysql_connection
    raise "Please pass path to mysql cnf file as first argument" unless File.exist?(ARGV.first)
    Mysql2::Client.new(default_file: ARGV.first)
  end

  def empty_migration
    ActiveRecord::Migrator.new(:up, [])
  end

  def non_locking_empty_migration
    NonLockingEmptyMigration.new(:up, [])
  end

  def lock_id
    @lock_id ||= empty_migration.send(:generate_migrator_advisory_lock_id)
  end
end

class NonLockingEmptyMigration < ActiveRecord::Migrator
    def migrate
      super unless runnable.empty?
    end
end
