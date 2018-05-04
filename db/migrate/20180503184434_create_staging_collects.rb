class CreateStagingCollects < ActiveRecord::Migration[5.1]
  def change
    create_table :staging_collects, id: false do |t|
      t.bigint :id, primary_key: true
      t.bigint :new_cc_id
      t.string :custom_collection_handle
      t.bigint :old_cc_id
      t.bigint :new_p_id
      t.string :product_handle
      t.bigint :old_p_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
