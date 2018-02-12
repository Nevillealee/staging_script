require "active_record"
require 'yaml'
require './elleStaging.rb'
require 'dotenv/load'
Dir["./models/*.rb"].each {|file| require file }

namespace :db do
  desc "Create the database"
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
  desc "saves product api response"
  task :pull_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     ProductAPI.copy_products_local
  end
end

namespace :customcollection do
  desc "saves custom collection response"
  task :pull_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CustomCollectionAPI.copy_collections_local
  end
  
  task :push_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CustomCollectionAPI.copy_collections_remote
  end
end

namespace :collect do
  desc "saves collect response"
  task :pull_actives do
    ActiveRecord::Base.establish_connection(
    {:adapter => 'postgresql',
     :database => 'test',
     :host => 'localhost',
     :port => '5432',
     :username => 'postgres',
     :password => 'postgres'})
     CollectAPI.copy_collects_local
  end
end
