require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
# automation suite GETs data from active ellie
# site, parses JSON responses, and POSTs to staging
# ellie site for testing
module CustomCollection
  # TODO(Neville lee) implement Durrells throttling algorithm
  # set ellie_active_url back to all custom_collections endpoint
  #
  # sets ellie active url to FIRST FIVE Custom Collections endpoint
  ellie_active_url = "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/custom_collections.json?limit=5"
  # GET request for all custom collections from ellieactive shop
  @active_collection = HTTParty.get(ellie_active_url)
  # iterates through custom collections to copy them to staging one by one
  # with the same titles. handles auto generated once POSTed
  def self.copyCollections
    # sets shopify gem to staging site
    ShopifyAPI::Base.site = "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    # grabs title of each custom collection to use as paramter for new
    # custom collection object created in POST request
    # to staging sight using ShopifyAPI gem
    @active_collection["custom_collections"].each do |current|
      ShopifyAPI::CustomCollection.create!(title: current["title"], template_suffix: current["template_suffix"])
    end
    p "transfer complete"
  end
  # prints custom collection keys arguement
  def self.printKey (key)
     @active_collection["custom_collections"].each do |x|
      p x[key]
    end
  end
  # prints all custom_collections from active site
  def self.print
    @response["custom_collections"].each do |x|
     p pp x
   end
  end
end

module Product
  # TODO(Neville lee) implement Durrells throttling algorithm
  # set ellie_active_url back to all products endpoint
  #
  # sets ellie active url to FIRST FIVE products endpoint
  ellie_active_url = "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/products.json?limit=5"
  # GET request for all products from ellieactive shop
  @active_product = HTTParty.get(ellie_active_url)
  # iterates through products to copy them to staging one by one
  # with the same titles. handles auto generated once POSTed
  def self.copyProducts
    # sets shopify gem to staging site
    ShopifyAPI::Base.site = "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    # grabs title, body_html, vendor, product_type, and variants
    # of each active product to use as paramters for new
    # product objects created in POST request
    # to staging sight using ShopifyAPI gem
    @active_product["product"].each do |current|
      ShopifyAPI::Product.create!(title: current["title"],
       body_html: current["body_html"],
       vendor: current["vendor"],
       product_type: current["product_type"],
       variants: current["variants"])
    end
    p "transfer complete"
  end
  # prints custom collection keys arguement
  def self.printKey (key)
     @active_collection["custom_collections"].each do |x|
      p x[key]
    end
  end
  # prints all custom_collections from active site
  def self.print
    @response["custom_collections"].each do |x|
     p pp x
   end
  end
end
