database_name = "smallfoot_#{Lucky::Env.name}"

Avram::Repo.configure do |settings|
  if Lucky::Env.production?
    settings.url = ENV.fetch("DATABASE_URL")
  else
    settings.url = ENV["DATABASE_URL"]? || Avram::PostgresURL.build(
      database: database_name,
      hostname: ENV["DB_HOST"]? || "localhost",
      # Some common usernames are "postgres", "root", or your system username (run 'whoami')
      username: ENV["DB_USERNAME"]? || "postgres",
      # Some Postgres installations require no password. Use "" if that is the case.
      password: ENV["DB_PASSWORD"]? || "postgres"
    )
  end
  # In development and test, raise an error if you forget to preload associations
  settings.lazy_load_enabled = Lucky::Env.production?
end

# puts "*" * 80, Lucky::Env.name + " " + Avram::Repo.settings.url, "*" * 80

# Avram::Migrator.run do
#   Avram::Migrator::Runner.new(false).run_pending_migrations
# end