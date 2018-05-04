class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products, id: false do |t|
      t.bigint :id, primary_key: true
      t.string :title, null: false
      t.string :body_html, default: ""
      t.string :vendor, null: false
      t.string :product_type, default: "", null: false
      t.string :handle
      t.string :template_suffix
      t.string :published_scope
      t.jsonb :images
      t.jsonb :image
      t.string :tags, array: true
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
