require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
# automation suite tranfers data from active ellie
# site, parses JSON responses, and POSTs to staging
# ellie site for testing
module CustomCollectionAPI
  # TODO(Neville lee): implement Durrells throttling algorithm
  # set ellie_active_url back to all custom_collections endpoint
  #
  # sets ellie active url to Custom Collections endpoint
  ellie_active_url =
  "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/custom_collections.json?limit=250"
  # GET request for all custom collections from ellieactive shop
  @active_collection = HTTParty.get(ellie_active_url)

  # iterates through custom collections to copy them to staging one by one
  # with the same titles. handles auto generated once POSTed
  def self.copy_collections_remote
    # sets shopify gem to staging site
    ShopifyAPI::Base.site =
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    # grabs title of each custom collection to use as paramter for new
    # custom collection object created in POST request
    # to staging sight using ShopifyAPI gem
    cc = CustomCollection.first
    # cc.each do |current|
      ShopifyAPI::CustomCollection.create!(title: cc.title,
      body_html: cc.body_html,
      sort_order: cc.sort_order,
      template_suffix: cc.template_suffix,
      published_scope: cc.published_scope)
    # end
    p "transfer complete"
  end

  def self.copy_collections_local
    # iterates through each custom collection
    # and saves copy to local db
    @active_collection["custom_collections"].each do |current|
      CustomCollection.create!(site_id: current["id"],
      handle: current["handle"],
      title: current["title"],
      body_html: current["body_html"],
      sort_order: current["sort_order"],
      template_suffix: current["template_suffix"],
      published_scope: current["published_scope"])
    end
    p "Custom Collections saved succesfully"
  end

  # prints custom collection keys arguement
  def self.printKeys(key)
     @active_collection["custom_collections"].each do |x|
      p x[key]
    end
  end
  # prints all custom_collections from active site
  def self.print
    @response["custom_collections"].each do |x|
      pp x
   end
  end
end

module ProductAPI
  # TODO(Neville lee) implement Durrells throttling algorithm
  # set ellie_active_url back to all products endpoint
  #
  # sets ellie active url to FIRST FIVE products endpoint
  ellie_active_url =
  "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/products.json?limit=250"
  # GET request for all products from ellieactive shop
  @active_product = HTTParty.get(ellie_active_url)

  # iterates through products to copy them to staging one by one
  # with the same titles. handles auto generated once POSTed

  def self.copy_products
    # sets shopify gem to staging site
    ShopifyAPI::Base.site =
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    # grabs title, body_html, vendor, product_type, and variants
    # of each active product to use as paramters for new
    # product objects created in POST request
    # to staging sight using ShopifyAPI gem
    @active_product["products"].each do |current|
      ShopifyAPI::Product.create!(title: current["title"],
       body_html: current["body_html"],
       vendor: current["vendor"],
       product_type: current["product_type"],
       variants: current["variants"],
       options: current["options"])
    end

    # notify user of succesful method complete otherwise
    # exception would be thrown by ShopifyAPI::Product.create! method above
    p "transfer complete"
  end

  # pulls product data from shopify api and saves to
  # database through  active record
  # TODO(Neville Lee): figure how to use this method and api
  # with active record

  def self.copy_products_local
    # loop iterates through each product returned
    # saving a copy locally in database attribute
    # by attribute
    @active_product["products"].each do |current|
      prod = Product.create!(title: current["title"],
       body_html: current["body_html"],
       vendor: current["vendor"],
       product_type: current["product_type"],
       handle: current["handle"],
       site_id: current["id"], # product id from ellie active
       template_suffix: current["template_suffix"],
       published_scope: current["published_scope"],
       tags: current["tags"],
       images: current["images"])
       # iterate through each nested variant array
       # inside each product for deep clone
       current["variants"].each do |current_variant|
         Variant.create!(site_id: current_variant["product_id"], # ID OF LINKED PRODUCT ON ellie ative
         product_id: prod.id, # LINK TO FK FOR active record ASSOCIATION
         title: current_variant["title"],
         option1: current_variant["option1"],
         sku: current_variant["sku"],
         price: current_variant["price"],
         barcode: current_variant["barcode"],
         compare_at_price: current_variant["compare_at_price"],
         fulfillment_service: current_variant["fulfillment_service"],
         grams: current_variant["grams"],
         image_id: current_variant["image_id"],
         inventory_management: current_variant["inventory_management"],
         inventory_policy: current_variant["inventory_policy"],
         weight_unit: current_variant["weight_unit"])
       end
       current["options"].each do |current_option|
         Option.create!(site_id: current_option["product_id"], #ID of LINKED product on ellie active
         product_id: prod.id,
         name: current_option["name"],
         position: current_option["position"],
         values: current_option["values"], #converts array of sizes into string
         images: current_option["images"],
         image: current_option["image"])
       end
    end
    p "Products saved succesfully"
  end

  # prints custom collection keys arguement
  def self.print_keys(key)
     @active_product["products"].each do |x|
      p x[key]
    end
  end

  # prints all custom_collections from active site
  def self.print
    @active_product["products"].each do |x|
     pp x
   end
  end
end

module CollectAPI
  # sets ellie active url to Custom Collections endpoint
  ellie_active_url =
  "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/collects.json?limit=250"
  # GET request for all custom collections from ellieactive shop
  @active_collection = HTTParty.get(ellie_active_url)

  def self.copy_collects_local
    # iterates through each custom collection
    # and saves copy to local db
    @active_collection["collects"].each do |current|
      Collect.create!(site_id: current["id"],
        collection_id: current["collection_id"],
        featured: current["featured"],
        position: current["position"],
        product_id: current["product_id"])
    end
    p "Collects succesfully saved"
  end
end
