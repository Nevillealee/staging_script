require 'active_record'
require 'yaml'
require 'dotenv/load'
Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }
require 'shopify_api'

db_config = YAML::load(File.open('db/database.yml'))
db_config_admin = db_config.merge({database: 'postgres', schema_search_path: 'public'})

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
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::Base.connection.execute(
      "TRUNCATE options,
      variants, products
      RESTART IDENTITY;")
     ProductAPI.active_to_db
  end

  desc "saves staging products to db"
  task :save_stages do
    ActiveRecord::Base.establish_connection(db_config)
     ProductAPI.stage_to_db
  end

  desc "pushes active products directly to staging"
  task :active_to_stage do
    ActiveRecord::Base.establish_connection(db_config)
     ProductAPI.active_to_stage
  end

  desc "pushes active products from db to staging"
  task :db_to_stage do
    ActiveRecord::Base.establish_connection(db_config)
     ProductAPI.db_to_stage
  end

  desc "update staging products from db"
  task :update_stages do
    ActiveRecord::Base.establish_connection(db_config)
     ProductAPI.stage_update
  end

  desc "deletes all staging products"
  task :delete do
    ActiveRecord::Base.establish_connection(db_config)
    ProductAPI.delete_all
  end
end

namespace :customcollection do
  desc "saves active custom collection to db"
  task :save_actives do
    ActiveRecord::Base.establish_connection(db_config)
     CustomCollectionAPI.active_to_db
  end

  desc "POSTs custom collections from db to staging"
  task :push_locals do
    ActiveRecord::Base.establish_connection(db_config)
     CustomCollectionAPI.db_to_stage
  end

  desc "saves staging custom collections to db"
  task :save_stages do
    ActiveRecord::Base.establish_connection(db_config)
     CustomCollectionAPI.stage_to_db
  end

  desc "deletes all staging custom collections"
  task :delete do
    ActiveRecord::Base.establish_connection(db_config)
    CustomCollectionAPI.delete_all
  end
end

namespace :collect do
  desc "saves active collects to db"
  task :save_actives do
    ActiveRecord::Base.establish_connection(db_config)
     CollectAPI.active_to_db
  end

  desc "pushes active collects in db to staging"
  task :push_locals do
    ActiveRecord::Base.establish_connection(db_config)
     CollectAPI.db_to_stage
  end

  desc "deletes all staging collects"
  task :delete do
    ActiveRecord::Base.establish_connection(db_config)
    CollectAPI.delete_all
  end
end

namespace :productmetafield do
  desc "saves active product's metafields to db"
  task :save_actives do
    ActiveRecord::Base.establish_connection(db_config)
     ProductMetafieldAPI.active_to_db
   end

   desc "pushes local product metafields to staging"
   task :push_locals do
     ActiveRecord::Base.establish_connection(db_config)
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
    ActiveRecord::Base.establish_connection(db_config)
     PageAPI.active_to_db
   end

  desc "pushes local pages to staging"
  task :push_locals do
   ActiveRecord::Base.establish_connection(db_config)
    PageAPI.db_to_stage
  end
end

namespace :blog do
  desc 'GET request for ellie.com blogs'
  task :save_actives do
    ActiveRecord::Base.establish_connection(db_config)
      BlogAPI.active_to_db
  end

  desc 'GET request for elliestaging blogs'
  task :save_stages do
    ActiveRecord::Base.establish_connection(db_config)
      BlogAPI.stage_to_db
  end

  desc 'POST request for elliestaging.com blogs'
  task :push_locals do
    ActiveRecord::Base.establish_connection(db_config)
      BlogAPI.db_to_stage
  end
end

namespace :article do
  desc 'GET request for ellie.com articles'
  task :save_actives  => ['blog:save_actives'] do
    ActiveRecord::Base.establish_connection(db_config)
      ArticleAPI.active_to_db
  end

  desc 'POST request for elliestaging articles'
  task :push_locals do
    ActiveRecord::Base.establish_connection(db_config)
      ArticleAPI.db_to_stage
  end
end

namespace :yotpos do
  desc 'pass in name of source csv (without ext) as an arguement'
  task :import, :csv_name do |t, args|
    ActiveRecord::Base.establish_connection(db_config)
      YotposAPI.import(args.csv_name)
  end

  desc 'tests join statement output AR'
  task :convert do
    ActiveRecord::Base.establish_connection(db_config)
      YotposAPI.convert_id
  end

  desc 'exports YOTPO csv'
  task :export do
    ActiveRecord::Base.establish_connection(db_config)
      YotposAPI.export
  end
end
