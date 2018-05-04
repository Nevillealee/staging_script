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
      t.belongs_to :product, index: true , foreign_key: true
    end
  end
end
