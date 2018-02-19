require 'active_record'
require 'yaml'
require 'dotenv/load'
Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }
require 'pp'
require 'shopify_api'

namespace :db do
  desc 'Create the database'
  task :create do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})

    ActiveRecord::Base.connection.create_database({
     :adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
        puts "Database created."
  end

  desc "Migrate the database"
  task :migrate do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})

    ActiveRecord::Migrator.migrate("db/migrate/")
    Rake::Task["db:schema"].invoke
    puts "Database migrated."
  end

  desc "Drop the database"
  task :drop do
    ActiveRecord::Base.establish_connection(db_config_admin)
    ActiveRecord::Base.connection.drop_database({:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     puts "Database deleted."
  end

  desc "Reset the database"
  task :reset => [:drop, :create, :migrate]

  desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
  task :schema do
    ActiveRecord::Base.establish_connection({:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
    require 'active_record/schema_dumper'
    filename = "db/schema.rb"

    File.open(filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end
end

namespace :g do
  desc "Generate migration"
  task :migration do
    name = ARGV[1] || raise("Specify name: rake g:migration your_migration")
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    path = File.expand_path("../db/migrate/#{timestamp}_#{name}.rb", __FILE__)
    migration_class = name.split("_").map(&:capitalize).join

    File.open(path, 'w') do |file|
      file.write <<-EOF
    class #{migration_class} < ActiveRecord::Migration
      def self.up
      end
      def self.down
      end
    end
      EOF
    end

    puts "Migration #{path} created"
    abort # needed stop other tasks
  end
end

namespace :product do
  desc "saves active product api response"
  task :save_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     ProductAPI.active_to_db
  end

  desc "saves staging products to db"
  task :save_stages do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     ProductAPI.stage_to_db
  end
end

namespace :customcollection do
  desc "saves active custom collection to db"
  task :save_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CustomCollectionAPI.active_to_db
  end

  desc "POSTs custom collections from db to staging"
  task :push_locals do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CustomCollectionAPI.db_to_stage
  end

  desc "saves staging custom collections to db"
  task :save_stages do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CustomCollectionAPI.stage_to_db
  end
end

namespace :collect do
  desc "saves active collects to db"
  task :save_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CollectAPI.active_to_db
  end

  desc "pushes active collects in db to staging"
  task :push_locals do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CollectAPI.db_to_stage
  end
end

namespace :productmetafield do
  desc "saves active product's metafields to db"
  task :save_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     ProductMetafieldAPI.active_to_db
   end

   desc "pushes local product metafields to staging"
   task :push_locals do
     ActiveRecord::Base.establish_connection(
     {:adapter => 'postgresql',
      :database => 'test',
      :host => 'localhost',
      :port => '5432',
      :username => 'postgres',
      :password => 'postgres'})
      ProductMetafieldAPI.db_to_stage
    end
end
