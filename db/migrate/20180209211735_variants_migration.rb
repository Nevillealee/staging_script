class VariantsMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :variants do |t|
      t.string :title
      t.integer :site_id
      t.string :option1, :null => false # mandatory field
      t.string :sku
      t.string :price
      t.string :barcode
      t.boolean :compare_at_price
      t.string :fulfillment_service
      t.integer :grams
      t.integer :image_id
      t.string :inventory_management
      t.string :inventory_policy
      t.string :weight_unit
      t.integer :product_id # foriegn key

      t.timestamps
    end

    # add an index on the foreign key to improve queries performance
    add_index :variants, :product_id
    # foreign key constraint to ensure referential data integrity
    add_foreign_key :variants, :products
  end
end
