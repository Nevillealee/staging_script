require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
require 'active_record'
Dir["./modules/*.rb"].each {|file| require file }
Dir["./models/*.rb"].each {|file| require file }

module ProductMetafieldAPI
  ActiveRecord::Base.establish_connection(
  {:adapter => 'postgresql',
   :database => 'test',
   :host => 'localhost',
   :port => '5432',
   :username => 'postgres',
   :password => 'postgres'})

def self.stage_to_db
  # Creates an array of distinct product ids (site_id field in db)
  # from latest GET Products request from ellie.com
  # saved into local db to use for metafield GET request loop.
  @product_ids = Product.select("site_id").distinct
  # Initialize ShopifyAPI gem with active site url
  ShopifyAPI::Base.site =
  "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin"

  @product_ids.each do |x|
    current_meta = ShopifyAPI::Metafield.all(params:
     {resource: 'products',
      resource_id: x.site_id,
      fields: 'namespace, key, value'})

      if current_meta[0] #TODO(Neville Lee): Verify what to do with products with no metafield
      # saves metafields for products with valid
      # namespace & that belong to a CustomCollection
      if current_meta[0].namespace != "EWD_UFAQ" &&
        ShopifyAPI::CustomCollection.find(:all, :params => { product_id: x.site_id })
        p "SAVE TO DB >>> #{x.site_id} = #{current_meta[0].namespace}, #{current_meta[0].key}, #{current_meta[0].value}"
        ProductMetafield.create(namespace: current_meta[0].namespace,
        key: current_meta[0].key,
        value: current_meta[0].value,
        owner_id: x.site_id)
      elsif ShopifyAPI::CustomCollection.find(:all, :params => { product_id: x.site_id })
        p "ADD METADATA >>> #{x.site_id}"
      else
        p "DO NOT SAVE >>> #{x.site_id}"
      end
    end
  end #product_ids loop
end # self.test
end # module

ProductMetafieldAPI.stage_to_db


def count_products
 ShopifyAPI::Base.site = "https://#{@apikey}:#{@password}@#{@shopname}.myshopify.com/admin"
 product_count = ShopifyAPI::Product.count
 puts "We have #{product_count} products"
 bad_product = 0
 visible_products = 0

 nb_pages = (product_count / 250.0).ceil
 1.upto(nb_pages) do |page|
     products = ShopifyAPI::Product.find( :all, :params => { :limit => 250, :page => page } )
     products.each do |product|
     puts "#{product.id} | #{product.title} | #{product.published_at}"
     if product.published_at != nil
         visible_products += 1
         end
     variants = product.variants
     variants.each do |variant|

         puts "#{product.title} -- #{variant.title}, #{variant.inventory_management}, #{variant.inventory_policy}"
         puts "#{variant.sku}, #{variant.inventory_quantity}, #{variant.old_inventory_quantity}"
         if  variant.inventory_management != 'shopify' && variant.inventory_policy != 'deny'
             bad_product += 1
         end



         end
     end
     puts 'sleeping 3'
     sleep 3


 end
 puts "We have #{bad_product} bad products"
 puts "we have #{visible_products} visible products"

end
