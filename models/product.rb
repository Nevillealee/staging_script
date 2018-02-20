class Product < ActiveRecord::Base
  validates_presence_of :title, :vendor
  has_many :variants, dependent: :destroy
  has_many :options, dependent: :destroy
end
