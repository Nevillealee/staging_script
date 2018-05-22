class AddGraphqlColumnToBlogs < ActiveRecord::Migration[5.1]
  def change
    add_column :blogs, :admin_graphql_api_id, :string
  end
end
