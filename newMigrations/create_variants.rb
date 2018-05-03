class CreateVariants < ActiveRecord::Migration[5.1]
  def change
    create_table :variants, id: false do |t|
      t.bigint :id, primary_key: true
      t.string :title
      t.string :option1, null: false
      t.string :sku, default: ""
      t.string :price
      t.string :barcode, default: ""
      t.boolean :compare_at_price
      t.string :fulfillment_service
      t.bigint :grams
      t.bigint :image_id
      t.string :inventory_management
      t.string :inventory_policy
      t.string :weight_unit
      t.bigint :product_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    # add an index on the foreign key to improve queries performance
    add_index :variants, :product_id
    # foreign key constraint to ensure referential data integrity
    add_foreign_key :variants, :products
  end
end
