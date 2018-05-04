require 'dotenv'
Dotenv.load
require 'sinatra'
set :database_file, "../config/database.yml"
require 'active_record'
require 'sinatra/activerecord/rake'
Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }

namespace :staging do
  desc "links products/customcollections on ellie staging"
  task :link_products =>
  ['product:save_actives',
    'product:save_stages',
    'customcollection:save_actives',
    'customcollection:save_stages',
    'collect:save_actives',
    'collect:push_locals'
    ] do
    p 'staging products successfully linked to staging custom collections'
  end
end

namespace :destroy do
  desc "deletes ALL products, custom_collections and collects from STAGING"
  task :staging =>
  ['product:delete',
  'customcollection:delete',
  'collect:delete'
  ] do
    p 'staging successfully wiped clean'
  end
end

namespace :product do
  desc "saves active product api response"
  task :save_actives do
  if Product.first
    ActiveRecord::Base.connection.execute("TRUNCATE options;")
    puts 'options table truncated'
    ActiveRecord::Base.connection.execute("TRUNCATE variants;")
    puts 'variants table truncated'
    ActiveRecord::Base.connection.execute("TRUNCATE products;")
    puts 'products table truncated'
  end
     ProductAPI.active_to_db
  end

  desc "saves staging products to db"
  task :save_stages do
    # ActiveRecord::Base.connection.execute(
    #   "TRUNCATE staging_products
    #   RESTART IDENTITY;")
    # ActiveRecord::Base.connection.execute("ALTER SEQUENCE staging_products_id_seq RESTART WITH 1;")
    #   puts "staging_product table truncated"
     ProductAPI.stage_to_db
  end

  desc "pushes active products directly to staging"
  task :active_to_stage do
     ProductAPI.active_to_stage
  end

  desc "pushes active products from db to staging"
  task :db_to_stage do
     ProductAPI.db_to_stage
  end

  desc "update staging products from db"
  task :update_stages do
     ProductAPI.stage_update
  end

  desc "deletes all staging products"
  task :delete do
    ProductAPI.delete_all
  end
end

namespace :customcollection do
  desc "saves active custom collection to db"
  task :save_actives do
     CustomCollectionAPI.active_to_db
  end

  desc "POSTs custom collections from db to staging"
  task :push_locals do
     CustomCollectionAPI.db_to_stage
  end

  desc "saves staging custom collections to db"
  task :save_stages do
     CustomCollectionAPI.stage_to_db
  end

  desc "deletes all staging custom collections"
  task :delete do
    CustomCollectionAPI.delete_all
  end
end

namespace :collect do
  desc "saves active collects to db"
  task :save_actives do
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
  desc "saves active product's metafields to db"
  task :save_actives do
     ProductMetafieldAPI.active_to_db
   end

   desc "pushes local product metafields to staging"
   task :push_locals do

      ProductMetafieldAPI.db_to_stage
    end

    desc 'transfers active product metafields onto ellie staging'
    task :update_stage => ['save_actives', 'push_locals'] do
      p 'product metafields ported from active to staging successfully'
    end
end

namespace :page do
  desc "saves active pages to db"
  task :save_actives do
     PageAPI.active_to_db
   end

  desc "pushes local pages to staging"
  task :push_locals do
 # ActiveRecord::Base.establish_connection(db_config)
    PageAPI.db_to_stage
  end
end

# To update blogs, run save_actives, push_locals, save_stages, article:save_actives
# and finally article:push_locals
namespace :blog do
  desc 'GET request for ellie.com blogs'
  task :save_actives do
    ActiveRecord::Base.connection.execute("TRUNCATE blogs;")
      BlogAPI.active_to_db
  end

  desc 'GET request for elliestaging blogs'
  task :save_stages do
    ActiveRecord::Base.connection.execute("TRUNCATE staging_blogs;")
      BlogAPI.stage_to_db
  end

  desc 'POST request for elliestaging.com blogs'
  task :push_locals do
      BlogAPI.db_to_stage
  end
end

namespace :article do
  desc 'GET request for ellie.com articles'
  task :save_actives  => ['blog:save_actives'] do
    ActiveRecord::Base.connection.execute("TRUNCATE articles;")
    ArticleAPI.active_to_db
  end

  desc 'POST request for elliestaging articles'
  task :push_locals do
      ArticleAPI.db_to_stage
  end
end

namespace :yotpos do
  desc 'pass in name of source csv (without ext) as an arguement'
  task :import_reviews, :csv_name do |t, args|
      YotposAPI.import(args.csv_name)
  end

  desc 'converts product ids from active to staging values'
  task :convert do
      YotposAPI.convert_id
  end

  desc 'exports YOTPO review csv'
  task :export_reviews do
      YotposAPI.export_reviews
  end

  desc 'exports YOTPO products import csv'
  task :export_products do
      YotposAPI.export_products
  end
end
