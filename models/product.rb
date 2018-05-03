class Product < ActiveRecord::Base
  has_many :variants, dependent: :destroy
  has_many :options, dependent: :destroy
end
