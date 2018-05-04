class CreateProductMetafields < ActiveRecord::Migration[5.1]
  def change
    create_table :product_metafields, id: false do |t|
      t.bigint :id, primary_key: true
      t.string :namespace
      t.string :key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :value
      t.bigint :owner_id
      t.string :value_type
      t.belongs_to :product, index: true, foreign_key: true
    end
  end
end
