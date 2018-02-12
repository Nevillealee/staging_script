class AddColumnsToOptions < ActiveRecord::Migration[5.1]
  def change
    rename_column :options, :one, :site_id
    change_column :options, :site_id, :string
    add_column :options, :name, :string
    add_column :options, :values, :string, array: true
    add_column :options, :images, :string, array: true
    add_column :options, :image, :string
  end
end
