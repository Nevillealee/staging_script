class CreatePages < ActiveRecord::Migration[5.1]
  def change
    create_table :pages do |t|
      t.string :site_id
      t.string :title, null: false
      t.string :shop_id
      t.string :handle
      t.string :body_html, default: ""
      t.string :author
      t.string :template_suffix
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
