class ChangeProductColumntype < ActiveRecord::Migration[5.1]
  def change
    change_column :products, :product_type, :string
  end
end
