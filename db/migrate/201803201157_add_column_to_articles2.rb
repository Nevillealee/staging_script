class AddColumnToArticles2 < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :summary_html, :string
    add_column :articles, :published_at, :timestamp
    add_column :articles, :metafields, :jsonb
  end
end
