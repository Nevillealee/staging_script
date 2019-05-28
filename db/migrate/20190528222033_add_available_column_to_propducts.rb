class AddAvailableColumnToPropducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :available, :boolean, default: false
    add_column :staging_products, :available, :boolean, default: false
  end
end
