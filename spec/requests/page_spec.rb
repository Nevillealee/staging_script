require 'active_record'
require 'shopify_api'
require 'spec_helper'
Dir['./modules/*.rb'].each { |file| require file }
Dir['./models/*.rb'].each { |file| require file }

RSpec.describe 'PageAPI' do
# TODO(Neville Lee): write test for api response
end
