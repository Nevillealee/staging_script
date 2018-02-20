require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
require 'active_record'
Dir["./modules/*.rb"].each {|file| require file }
Dir["./models/*.rb"].each {|file| require file }

module ProductMetafieldAPI
  def self.shopify_api_throttle
    return if ShopifyAPI.credit_left > 5
    puts "CREDITS LEFT: #{ShopifyAPI.credit_left}"
    puts "SLEEPING 10"
    sleep 10
  end

def self.active_to_db
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

      if  current_meta != nil && current_meta[0]  #(Neville Lee): Verify what to do with products with no metafield
      # saves metafields for products with valid
      # namespace & that belong to a CustomCollection
      if current_meta[0].namespace != "EWD_UFAQ" &&
        ShopifyAPI::CustomCollection.find(:all, :params => { product_id: x.site_id })
          p "SAVE TO DB >>> #{x.site_id} = #{current_meta[0].namespace}, #{current_meta[0].key}, #{current_meta[0].value}"
          # save current validated metafield to db
        ProductMetafield.create(namespace: current_meta[0].namespace,
        key: current_meta[0].key,
        value: current_meta[0].value,
        value_type: 'string',
        owner_id: x.site_id)
      elsif ShopifyAPI::CustomCollection.find(:all, :params => { product_id: x.site_id })
        # POST new metafield object
        p "ADD METADATA >>> #{x.site_id}"
      else
        p "DO NOT SAVE >>> #{x.site_id}"
      end
    end
  end #product_ids loop
  p "active product metafields saved successfully"
end # self.test

# creates an array of all product_metafields from db
# iterates through array creating new product_metafields
# one by on with shopify gem method

def self.db_to_stage
  ShopifyAPI::Base.site =
  "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"

  # Join product_metafields, products and staging_products
  # to link staging product_id to active product_id
  # before creating product_metafields with new
  # staging_product_id as owner_id
  @metafields = ProductMetafield.find_by_sql(
  "SELECT product_metafields .*,
   p.title as active_product,
    sp.site_id as staging_product_id FROM product_metafields
    INNER JOIN products p ON product_metafields.owner_id = p.site_id
    INNER JOIN staging_products sp ON p.title = sp.title;")
  p 'pushing  local product_metafields to staging..'

  @metafields.each do |current|
    self.shopify_api_throttle
    myprod = ShopifyAPI::Product.find(current.staging_product_id)
    myprod.add_metafield(ShopifyAPI::Metafield.new( {
    namespace: current.namespace,
    key: current.key,
    value: current.value,
    value_type: current.value_type } ))
    myprod.save
  end
  p 'product_metafields successfully pushed to staging'
end
end
