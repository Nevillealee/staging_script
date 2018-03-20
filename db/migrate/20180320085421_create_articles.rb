class CreateArticles < ActiveRecord::Migration[5.1]
  def change
    create_table :articles, id: false do |t|
      t.bigint :id, null: false, primary_key: true
      t.string :title
      t.bigint :blog_id
      t.string :author
      t.string :body_html
      t.string :handle
      t.jsonb :image
      t.boolean :published
      t.string :tags
      t.string :template_suffix
      t.bigint :user_id
    end
  end
end