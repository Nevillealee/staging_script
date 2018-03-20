class AddColumnToBlogs < ActiveRecord::Migration[5.1]
  def change
    add_column :blogs, :updated_at, :timestamp
    add_column :articles, :updated_at, :timestamp
  end
end
