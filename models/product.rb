class Product < ActiveRecord::Base
  validates_presence_of :title, :vendor, :product_type
  has_many :variants, dependent: :destroy
  # TODO(Neville Lee): has_one?
  has_many :options, dependent: :destroy
  # TODO(Neville Lee): has_one?
  has_many :product_metafields, dependent: :destroy
end
