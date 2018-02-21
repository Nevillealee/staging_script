require 'active_record'
require './models/product.rb'
require 'spec_helper'

# Non-rails related specs do not require `:type` metadata by default
RSpec.describe Product, :type => :model do
  let(:product) { create(:product) }
  # Validation tests
  context 'before api call is made' do
    it 'is valid with title, vendor, product_type fields' do
      expect(product).to be_valid
    end

    it 'is invalid without title, vendor, or product_type' do
      # creates product without attributes
      expect(Product.create(vendor: 'fam brands')).not_to be_valid
    end
  end

  context 'after api call is made' do
    it 'database should have valid products fields' do
    end
  end
end
