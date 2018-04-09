class Yotpo < ActiveRecord::Base
  self.primary_key = "id"
  has_many :staging_products
end
