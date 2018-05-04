class CreateYotpos < ActiveRecord::Migration[5.1]
  def change
    create_table :yotpos, id: false do |t|
      t.bigint :id, null: false, primary_key: true
      t.string :user_type
      t.string :appkey
      t.boolean :published
      t.string :review_title
      t.string :review_content
      t.integer :review_score
      t.datetime :date
      t.string :product_id
      t.string :product_url
      t.string :product_title
      t.string :product_description
      t.string :product_image_url
      t.string :display_name
      t.string :email
      t.string :comment_content
      t.string :comment_public
      t.datetime :comment_created_at
      t.string :published_image_url
      t.string :unpublished_image_url
      t.string :cf_Default_form_Fit
    end
  end
end
