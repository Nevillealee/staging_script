class CreateStagingBlogs < ActiveRecord::Migration[5.1]
  def change
    create_table :staging_blogs, id: false do |t|
      t.bigint :id, null: false, primary_key: true
      t.string :title
      t.string :handle
      t.string :commentable
      t.string :feedburner
      t.string :feedburner_location
      t.string :template_suffix
      t.string :tags
      t.datetime :updated_at
      t.datetime :created_at
      t.string :admin_graphql_api_id
    end
  end
end
