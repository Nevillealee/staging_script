class CreateOptions < ActiveRecord::Migration[5.1]
  def change
    create_table :options, id: false do |t|
      t.bigint :id, primary_key: true
      t.bigint :product_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :name
      t.string :values, array: true
      t.string :images, array: true
      t.string :image
      t.integer :position
    end
    # add an index on the foreign key to improve queries performance
    add_index :options, :product_id
    # foreign key constraint to ensure referential data integrity
    add_foreign_key :options, :products
  end
end
