class CreateStagingCollects < ActiveRecord::Migration[5.1]
  def change
    create_table :staging_collects do |t|
      t.string :new_cc_id
      t.string :custom_collection_handle
      t.string :old_cc_id
      t.string :new_p_id
      t.string :product_handle
      t.string :old_p_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
