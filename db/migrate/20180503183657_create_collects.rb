class CreateCollects < ActiveRecord::Migration[5.1]
  def change
    create_table :collects, id: false do |t|
      t.bigint :id, primary_key: true
      t.bigint :collection_id
      t.integer :position
      t.bigint :product_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
