class ChangeTagColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :staging_products, :tags, :string
    change_column :products, :tags, :string
  end
end
