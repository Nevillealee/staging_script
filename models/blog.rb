class Blog < ActiveRecord::Base
  has_many :articles, foreign_key: :blog_id
end
