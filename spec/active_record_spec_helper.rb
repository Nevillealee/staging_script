# file establishes connection to database
# for active record use during rspec tests
RSpec.configure do |config|
  config.before(:suite) do
  db_config = YAML::load(File.open('db/database.yml'))
  ActiveRecord::Base.establish_connection(db_config)
  end
end
