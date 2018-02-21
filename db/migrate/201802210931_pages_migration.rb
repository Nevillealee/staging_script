class PagesMigration < ActiveRecord::Migration[5.1]
  def change
    create_table :pages do |t|
      t.string :site_id
      t.string :title, null: false # mandatory field
      t.string :shop_id
      t.string :handle
      t.string :body_html, default: ''
      t.string :author
      t.string :template_suffix

      t.timestamps
    end
  end
end
