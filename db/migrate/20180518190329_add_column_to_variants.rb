class AddColumnToVariants < ActiveRecord::Migration[5.1]
  def change
    add_column :variants, :inventory_quantity, :string
    change_column :variants, :compare_at_price, :string
  end
end
