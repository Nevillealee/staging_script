class ProductsMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.integer :site_id # links product to collects
      t.string :title, :null => false # mandatory field
      t.string :body_html, :default => ""
      t.string :vendor, :null => false # mandatory field
      t.string :product_type, :null => false # mandatory field
      t.string :handle
      t.string :template_suffix
      t.string :published_scope
      # usage(images: { kind: "user_renamed", change: ["jack", "john"]})
      t.jsonb :images
      t.string :tags, array: true  # stores tags an array of strings
      t.string :options, array: true # TODO(Neville lee): serialize model as hash

      t.timestamps
    end
  end
end
