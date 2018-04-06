require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
Dir['./models/*.rb'].each { |file| require file }

module YotposAPI
  
end
