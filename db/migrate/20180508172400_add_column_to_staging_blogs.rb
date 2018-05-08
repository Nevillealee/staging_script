class AddColumnToStagingBlogs < ActiveRecord::Migration[5.1]
  def change
    add_column :staging_blogs, :admin_graphql_api_id, :string
  end
end
