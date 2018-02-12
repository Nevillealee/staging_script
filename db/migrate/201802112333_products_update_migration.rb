class ProductsUpdateMigration < ActiveRecord::Migration[5.1]
  def up
    remove_column :products, :options
  end

  def down
    add_column :products, :options, :jsonb
  end
end
