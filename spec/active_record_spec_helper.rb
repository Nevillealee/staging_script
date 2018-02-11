# file establishes connection to database
# for active record use during rspec tests
RSpec.configure do |config|
  config.before(:suite) do
  ActiveRecord::Base.configurations =
      YAML.load_file(File.expand_path("../../db/database.yml", __FILE__))
  ActiveRecord::Base.establish_connection({
   :adapter => 'postgresql',
   :database => 'test',
   :host => 'localhost',
   :port => '5432',
   :username => 'postgres',
   :password => 'postgres'})
  end
end
