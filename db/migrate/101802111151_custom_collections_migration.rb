class CustomCollectionsMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_collections do |t|
      t.string :site_id
      t.string :handle
      t.string :title
      t.string :body_html
      t.string :sort_order
      t.string :template_suffix
      t.string :published_scope

      t.timestamps
    end
  end
end
