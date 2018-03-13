class UpdateVariantsTable < ActiveRecord::Migration[5.1]
  def change
    change_column :variants, :sku, :string, default: ''
  end
end
