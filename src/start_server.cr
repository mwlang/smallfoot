require "./app"

if Lucky::Env.development?
  Avram::Migrator::Runner.new.ensure_migrated!
end
Habitat.raise_if_missing_settings!

puts "Preparing Smallfoot"

app_server = AppServer.new

Signal::INT.trap do
  puts "closing!"
  app_server.close
end

puts "Smallfoot ready!"
app_server.listen
