class CreateStagingProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :staging_products do |t|
      t.string :site_id
      t.string :title, null: false
      t.string :body_html
      t.string :vendor, null: false
      t.string :product_type
      t.string :handle
      t.string :template_suffix
      t.string :published_scope
      t.jsonb :images
      t.string :tags, array: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.jsonb :image
    end
  end
end
