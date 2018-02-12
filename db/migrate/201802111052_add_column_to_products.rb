class AddColumnToProducts < ActiveRecord::Migration[5.1]
  def change
    change_column :products, :site_id, :string
  end
end
