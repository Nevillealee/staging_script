class UpdateProductColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :products, :product_type, :string, default: ''
  end
end
