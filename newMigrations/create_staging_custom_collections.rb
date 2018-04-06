class CreateStagingCustomCollections < ActiveRecord::Migration[5.1]
  def change
    create_table :staging_custom_collections do |t|
      t.string :site_id
      t.string :handle
      t.string :title
      t.string :body_html
      t.string :sort_order
      t.string :template_suffix
      t.string :published_scope
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
