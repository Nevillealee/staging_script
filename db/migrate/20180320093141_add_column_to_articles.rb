class AddColumnToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :blogs, :created_at, :timestamp
    add_column :articles, :created_at, :timestamp
  end
end
