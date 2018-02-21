class AddColumnToProducts3 < ActiveRecord::Migration[5.1]
    def change
      add_column :products, :image, :jsonb
  end
end
