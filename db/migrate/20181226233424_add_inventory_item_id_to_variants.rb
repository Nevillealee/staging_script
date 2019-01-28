class AddInventoryItemIdToVariants < ActiveRecord::Migration[5.1]
  def change
    add_column :variants, :inventory_item_id, :bigint
  end
end
