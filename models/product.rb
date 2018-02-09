class Product < ActiveRecord::Base
  has_many :variants, dependent: :destroy
  # TODO(Neville Lee): has_one?
  has_many :options, dependent: :destroy
  # TODO(Neville Lee): has_one?
  has_many :product_metafields, dependent: :destroy
end
