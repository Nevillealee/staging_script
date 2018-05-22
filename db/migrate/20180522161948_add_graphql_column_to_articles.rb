class AddGraphqlColumnToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :admin_graphql_api_id, :string
  end
end
