class ChangeVariantsColumn2 < ActiveRecord::Migration[5.1]
  def change
    change_column :variants, :grams, :bigint
    change_column :variants, :image_id, :bigint
  end
end
