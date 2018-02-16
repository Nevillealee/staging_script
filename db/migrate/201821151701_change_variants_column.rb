class ChangeVariantsColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :variants, :product_id, :bigint
  end
end
