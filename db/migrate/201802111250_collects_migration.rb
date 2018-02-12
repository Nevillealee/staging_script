class CollectsMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :collects do |t|
      t.string :collection_id
      t.boolean :featured
      t.string :site_id
      t.integer :position
      t.string :product_id # product site id value

      t.timestamps
    end

  end
end
