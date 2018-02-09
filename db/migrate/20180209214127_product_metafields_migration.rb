class ProductMetafieldsMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :product_metafields do |t|
      t.string :namespace
      t.string :namespace_key
      t.integer :product_id # foriegn key

      t.timestamps
    end

    # add an index on the foreign key to improve queries performance
    add_index :product_metafields, :product_id
    # foreign key constraint to ensure referential data integrity
    add_foreign_key :product_metafields, :products
  end
end
