class AddColumnToProductMetafields < ActiveRecord::Migration[5.1]
  def change
    rename_column :product_metafields, :namespace_key, :key
    add_column :product_metafields, :value, :string
    add_column :product_metafields, :owner_id, :string
    add_column :product_metafields, :value_type, :string
  end
end
