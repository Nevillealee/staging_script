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
    ActiveRecord::Base.connection.execute("TRUNCATE products CASCADE;")
    ProductAPI.active_to_db
  else
    ProductAPI.active_to_db
  end
 end

  desc "nuke->pull staging products"
  task :save_stages do
    ActiveRecord::Base.connection.execute("TRUNCATE staging_products;") if StagingProduct.exists?
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

  desc "delete all products from elliestaging"
  task :delete do
    ProductAPI.delete_duplicates
  end

  desc "fix leading zero skus from marika"
  task :fix_skus do
    ProductAPI.fix_skus
  end

end

namespace :customcollection do
  desc "nuke/pull active custom collection to db"
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE custom_collections;") if CustomCollection.exists?
    CustomCollectionAPI.active_to_db
  end

  desc "POSTs custom collections from db to staging"
  task :push_locals do
     CustomCollectionAPI.db_to_stage
  end

  desc "saves staging custom collections to db"
  task :save_stages do
    ActiveRecord::Base.connection.execute("TRUNCATE staging_custom_collections;") if StagingCustomCollection.exists?
    CustomCollectionAPI.stage_to_db
  end

  desc "deletes all staging custom collections"
  task :delete do
    CustomCollectionAPI.delete_all
  end

  desc "appends hardcoded exclusives collections together"
  task :append do
    CustomCollectionAPI.append_exclusives
  end
end

namespace :collect do
  desc "nuke/pull active collects"
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE collects;") if Collect.exists?
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
   ActiveRecord::Base.connection.execute("TRUNCATE product_metafields;") if ProductMetafield.exists?
   ProductMetafieldAPI.active_to_db
  end

  desc "push local product metafields to staging"
  task :push_locals do
    ProductMetafieldAPI.db_to_stage
  end

  desc 'transfer active product metafields->ellie staging'
  task :update_stage => ['save_actives', 'push_locals'] do
    p 'product metafields ported from active to staging successfully'
  end
end

namespace :page do
  desc "nuke/pull active pages"
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE pages;") if Page.exists?
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
      ActiveRecord::Base.connection.execute("TRUNCATE blogs;") if Blog.exists?
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
    ActiveRecord::Base.connection.execute("TRUNCATE articles;") if Article.exists?
    ArticleAPI.active_to_db
  end

  desc 'push local articles->elliestaging'
  task :push_locals do
      ArticleAPI.db_to_stage
  end
end

desc 'tag products in collection id given'
task :tag_collection, [:args] do |t, args|
  ProductAPI.tag_collection_products(*args)
end
