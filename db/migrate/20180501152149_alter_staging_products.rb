  class AlterStagingProducts < ActiveRecord::Migration[5.1]
    def change
      add_column :staging_products, :variants, :jsonb
      add_column :staging_products, :options, :jsonb
    end
  end
