class Collect < ActiveRecord::Base
  # has_one :product, foreign_key: 'site_id', primary_key: 'product_id'
  # has_one :staging_product, through: :product, foreign_key: 'site_id', primary_key: 'product_id'
end
