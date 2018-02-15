class RemoveColumnFromProductMetafields < ActiveRecord::Migration[5.1]
  def change
    remove_column :product_metafields, :product_id
  end
end
