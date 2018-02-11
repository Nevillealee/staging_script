require 'active_record'
require './models/product.rb'
require 'spec_helper'

# Non-rails related specs do not require `:type` metadata by default
RSpec.describe Product, :type => :model do
  #Association test
  #ensure Product model has one:many relationship with Option model
  it 'should have_many options, dependant :destroy'
  #
  # Validation tests
  #ensure columns title and created_by are not null before saving
  it 'should validate presence of(:title)'
  it 'should validate presence of(:vendor)'
  it 'should validate presence of(:product_type)'
end
