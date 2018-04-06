class CreateCollects < ActiveRecord::Migration[5.1]
  def change
    create_table :collects do |t|
      t.string :collection_id
      t.boolean :featured
      t.string :site_id
      t.integer :position
      t.string :product_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
