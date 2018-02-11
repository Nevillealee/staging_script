require 'factory_bot'

# Rspec without rails FactoryBot configuration
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
