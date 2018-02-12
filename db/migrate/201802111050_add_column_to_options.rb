class AddColumnToOptions < ActiveRecord::Migration[5.1]
  def change
    add_column :options, :position, :integer
  end
end
