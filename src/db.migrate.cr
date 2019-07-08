require "./shards"
require "./models/base_model"
require "./models/mixins/**"
require "./models/**"
require "./queries/mixins/**"
require "./queries/**"
require "../config/env"
require "../config/database"
require "../db/migrations/**"


class Avram::Migrator::Runner

  private def setup_migration_tracking_tables
    DB.open(Avram::Repo.settings.url) do |db|
      db.exec create_table_for_tracking_migrations
    end
  end

  private def prepare_for_migration
    setup_migration_tracking_tables
    if pending_migrations.empty?
      unless @quiet
        puts "Did not migrate anything because there are no pending migrations.".colorize(:green)
      end
    else
      yield
    end
  rescue e : DB::ConnectionRefused
    puts e.inspect
    puts "@" * 80, Avram::Repo.settings.url, "@" * 80
    raise "Unable to connect to the database. Please check your configuration.".colorize(:red).to_s
  rescue e : Exception
    puts e.inspect
    puts "@" * 80, Avram::Repo.settings.url, "@" * 80
    raise "Unexpected error while running migrations: #{e.message}".colorize(:red).to_s
  end

end

puts "*" * 80, Lucky::Env.name + " " + Avram::Repo.settings.url, "*" * 80
Avram::Migrator.run do
  Avram::Migrator::Runner.new(false).run_pending_migrations
end