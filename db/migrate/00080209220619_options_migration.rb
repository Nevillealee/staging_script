class OptionsMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :options do |t|
      t.jsonb :one # TODO(Nevile Lee): verify correct column type
      t.integer :product_id # foriegn key

      t.timestamps
    end

    # add an index on the foreign key to improve queries performance
    add_index :options, :product_id
    # foreign key constraint to ensure referential data integrity
    add_foreign_key :options, :products
  end
end
