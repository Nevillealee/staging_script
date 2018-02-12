class VariantsSiteidTypeMigration < ActiveRecord::Migration[5.1]
  def change
    change_column :variants, :site_id, :string
  end
end
