class AddColumnToCollects < ActiveRecord::Migration[5.1]
  def change
    add_column :collects, :featured, :boolean
    add_column :staging_collects, :featured, :boolean
  end
end
