class CreateProductMetafields < ActiveRecord::Migration[5.1]
  def change
    create_table :product_metafields do |t|
      t.string :namespace
      t.string :key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :value
      t.bigint :owner_id
      t.string :value_type
    end
    # add an index on the foreign key to improve queries performance
    add_index :product_metafields, :product_id
    # foreign key constraint to ensure referential data integrity
    add_foreign_key :product_metafields, :products
  end
end
