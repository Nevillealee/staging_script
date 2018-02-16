class ChangeOptionsColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :options, :product_id, :bigint
  end
end
