require 'dotenv'
Dotenv.load
require 'sinatra'
set :database_file, "../config/database.yml"
require 'active_record'
require 'sinatra/activerecord/rake'
Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }

namespace :staging do
  desc "migrates collect/collection/products/metafields to ellie staging"
  task :migrate =>
  ['product:save_actives',
    'product:save_stages', # then rake product:db_to_stage then rake product:save_stages
    'product:db_to_stage',
    'product:save_stages',
    'customcollection:save_actives',
    'customcollection:save_stages', # then push active to staging then resave staging
    'customcollection:push_locals',
    'customcollection:save_stages',
    'collect:save_actives',
    'collect:push_locals',
    'productmetafield:save_actives',
    'productmetafield:update_stage',
    ] do
    p 'ellie successfully migrated to ellie staging'
  end
end

namespace :destroy do
  desc "DELETES ALL products, custom_collections and collects from STAGING"
  task :staging =>
  ['product:delete',
  'customcollection:delete',
  'collect:delete'
  ] do
    p 'staging successfully wiped clean'
  end
end

namespace :product do
  desc "nuke->pull active products"
  task :save_actives do
  if Product.exists?
    ActiveRecord::Base.connection.execute("TRUNCATE products RESTART IDENTITY CASCADE;")
    ProductAPI.active_to_db
  else
    ProductAPI.active_to_db
  end
 end

  desc "nuke->pull staging products"
  task :save_stages do
    # method skips existing staging products based on handle, TRUNCATE unecessary
    # ActiveRecord::Base.connection.execute("TRUNCATE staging_products RESTART IDENTITY;") if StagingProduct.exists?
    ProductAPI.stage_to_db
  end

  desc "push active products->staging"
  task :active_to_stage do
     ProductAPI.active_to_stage
  end

  desc "push active products from db to staging"
  task :db_to_stage do
     ProductAPI.db_to_stage
  end

  desc "update staging products from db"
  task :update_stage_attr do
     ProductAPI.stage_attr_update
  end

  desc "delete all dup staging products"
  task :delete_dups do
    ProductAPI.delete_dups
  end

  desc "fix leading zero skus from marika"
  task :fix_skus do
    ProductAPI.fix_skus
  end

  desc "Update inventory on staging"
  task :inventory_to_stage do
    ProductAPI.inventory_update
  end

end

namespace :customcollection do
  desc "nuke/pull active custom collection to db"
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE custom_collections RESTART IDENTITY;") if CustomCollection.exists?
    CustomCollectionAPI.active_to_db
  end

  desc "POSTs custom collections from db to staging"
  task :push_locals do
     CustomCollectionAPI.db_to_stage
  end

  desc "saves 'new' staging custom collections to db"
  task :save_stages do
    # ActiveRecord::Base.connection.execute("TRUNCATE staging_custom_collections RESTART IDENTITY;")
    CustomCollectionAPI.stage_to_db
  end

  desc "deletes duplicate staging custom collections"
  task :delete_dups do
    CustomCollectionAPI.delete_dups
  end

  desc "appends hardcoded exclusives collections together"
  task :append do
    CustomCollectionAPI.append_exclusives
  end

  desc "adds tag to all products in collection"
  task :tag_products do
    CustomCollectionAPI.add_product_tags('91469578298', 'ellie-exclusive')
  end

  desc "removes tag in all products in 'collection'"
  task :untag_products do
    CustomCollectionAPI.remove_product_tags
  end
end

namespace :collect do
  desc "nuke/pull active collects"
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE collects RESTART IDENTITY;") if Collect.exists?
    CollectAPI.active_to_db
  end

  desc "pushes active collects in db to staging"
  task :push_locals do
     CollectAPI.db_to_stage
  end

  desc "deletes all staging collects"
  task :delete do
    CollectAPI.delete_all
  end
end

namespace :productmetafield do
  desc "pull active product metafields"
  task :save_actives do
   ActiveRecord::Base.connection.execute("TRUNCATE product_metafields RESTART IDENTITY;") if ProductMetafield.exists?
   ProductMetafieldAPI.active_to_db
  end

  desc "push local product metafields to staging"
  task :push_locals do
    ProductMetafieldAPI.db_to_stage
  end

  desc "update staging product metafields"
  task :update_stage do
   ProductMetafieldAPI.update_staging
  end
end

namespace :page do
  desc "nuke/pull active pages"
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE pages RESTART IDENTITY;") if Page.exists?
    PageAPI.active_to_db
   end

  desc "push local pages->staging"
  task :push_locals do
    PageAPI.db_to_stage
  end
end

# NUKE staging then...To update blogs, run save_actives, push_locals, save_stages, article:save_actives
# and finally article:push_locals
namespace :blog do
  desc 'nuke/pull ellie.com blogs'
  task :save_actives do
      ActiveRecord::Base.connection.execute("TRUNCATE blogs RESTART IDENTITY;") if Blog.exists?
      BlogAPI.active_to_db
  end

  desc 'pull elliestaging blogs'
  task :save_stages do
    ActiveRecord::Base.connection.execute("TRUNCATE staging_blogs;")
      BlogAPI.stage_to_db
  end

  desc 'push local blogs->elliestaging'
  task :push_locals do
      BlogAPI.db_to_stage
  end
end

namespace :article do
  desc 'nuke/pull ellie.com articles'
  task :save_actives  => ['blog:save_actives'] do
    ActiveRecord::Base.connection.execute("TRUNCATE articles RESTART IDENTITY;") if Article.exists?
    ArticleAPI.active_to_db
  end

  desc 'push local articles->elliestaging'
  task :push_locals do
      ArticleAPI.db_to_stage
  end
end

namespace :recharge do
  desc "(1)pull all recharge ACTIVE queued orders"
  task :pull_actives do
    OrderAPI::Recent.new.get_full_background_orders
  end

  desc "(2)set orders w/o sub_id to false"
  task :mark_falses do
    OrderAPI::Recent.new.mark_falses
  end

  desc "(3)update order sub ids"
  task :match_sub_ids do
    OrderAPI::Recent.new.match_sub_ids
  end

  desc "(4)update recharge API with correct orders"
  task :update_api do
    OrderAPI::Recent.new.update_api
  end
end
