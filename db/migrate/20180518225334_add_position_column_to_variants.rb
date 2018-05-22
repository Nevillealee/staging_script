class AddPositionColumnToVariants < ActiveRecord::Migration[5.1]
  def change
    add_column :variants, :position, :string
  end
end
