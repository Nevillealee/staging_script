class ChangeVariantBarcode < ActiveRecord::Migration[5.1]
  def change
    change_column :variants, :barcode, :string, default: ''
  end
end
