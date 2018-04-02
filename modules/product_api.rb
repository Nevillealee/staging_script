require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

# Internal: Automate GET, POST, PUT requests to Ellie.com
# and Elliestaging shopify sites for products cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake product:save_stages
module ProductAPI
  ACTIVE_PRODUCT = []
  STAGING_PRODUCT = []

  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    sleep 10
  end


  def self.init_actives
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    active_product_count = ShopifyAPI::Product.count
    nb_pages = (active_product_count / 250.0).ceil

    # Initalize ACTIVE_PRODUCT with all active products from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url =
        "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/products.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_active_url)
      # appends each product hash to ACTIVE_PRODUCT array
      ACTIVE_PRODUCT.push(@parsed_response['products'])
      p "active products set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'active products initialized'
    # combine hash arrays from each page
    # into single product array
    ACTIVE_PRODUCT.flatten!
  end

  def self.init_stages
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    staging_product_count = ShopifyAPI::Product.count
    nb_pages = (staging_product_count / 250.0).ceil

    # Initalize @STAGING_PRODUCT with all staging products from elliestaging
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_staging_url =
        "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin/products.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_staging_url)
      # appends each product hash to STAGING_PRODUCT array
      STAGING_PRODUCT.push(@parsed_response['products'])
      p "staging products set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'staging products initialized'
    # combine hash arrays from each page
    # into single product array
    STAGING_PRODUCT.flatten!
  end

  # saves ellie staging products
  # without variants or options attributes.
  # primary use for cloning active collections

  def self.stage_to_db
    init_stages
    p 'saving staging products...'

    STAGING_PRODUCT.each do |current|
        StagingProduct.create(
        title: current['title'],
        site_id: current['id'],
        body_html: current['body_html'],
        vendor: current['vendor'],
        product_type: current['product_type'],
        handle: current['handle'],
        template_suffix: current['template_suffix'] || '',
        published_scope: current['published_scope'],
        tags: current['tags'],
        images: current['images'],
        image: current['image'])
    end
    p 'staging products saved to db'
  end

def self.active_to_stage
  init_actives
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  # grabs title, body_html, vendor, product_type, and variants
  # of each active product to use as paramters for new
  # product objects created in POST request
  # to staging sight using ShopifyAPI gem

  p 'transferring active products to staging...'
  ACTIVE_PRODUCT.each do |current|
    ProductAPI.shopify_api_throttle
    # p current['title']
    begin
    ShopifyAPI::Product.create(
     title: current['title'],
     vendor: current['vendor'],
     body_html: current['body_html'],
     handle: current['handle'],
     product_type: current['product_type'],
     template_suffix: current['template_suffix'] || "",
     variants: current['variants'],
     options: current['options'],
     images: current['images'],
     image: current['image'])
   rescue
     p "error with #{current['title']}"
     next
   end
  end
  # notify user of succesful method complete otherwise
  # exception would be thrown by ShopifyAPI::Product.create! method above
  p 'transfer complete'
end

def self.db_to_stage
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  # grabs title of each product to use as paramter for new
  # custom collection object created in POST request
  # to staging sight using ShopifyAPI gem
  product = Product.all
  p 'pushing products to shopify...'
  product.each do |current|
    shopify_api_throttle
    ShopifyAPI::Product.create!(
     title: current['title'],
     vendor: current['vendor'],
     body_html: current['body_html'],
     handle: current['handle'],
     product_type: current['product_type'],
     template_suffix: current['template_suffix'] || "",
     variants: current.variants.as_json,
     options: current.options.as_json,
     images: current['images'] || "",
     image: current['image'] || "")
     p "saved  #{current['title']}"
  end
end

# pulls active product data from shopify api and saves to
# database through  active record
def self.active_to_db
  init_actives

  ACTIVE_PRODUCT.each do |current|
    prod = Product.create!(
    title: current['title'],
    body_html: current['body_html'],
    vendor: current['vendor'],
    product_type: current['product_type'],
    handle: current['handle'],
    site_id: current['id'], # product id from ellie active
    template_suffix: current['template_suffix'],
    published_scope: current['published_scope'],
    tags: current['tags'],
    images: current['images'])
    # iterate through each nested variant array
    # inside each product for deep clone
    current['variants'].each do |current_variant|
      Variant.create!(
      site_id: current_variant['product_id'], # ID OF LINKED PRODUCT ON ellie ative
      product_id: prod.id, # LINK TO FK FOR active record ASSOCIATION
      title: current_variant['title'],
      option1: current_variant['option1'],
      sku: current_variant['sku'],
      price: current_variant['price'],
      barcode: current_variant['barcode'],
      compare_at_price: current_variant['compare_at_price'],
      fulfillment_service: current_variant['fulfillment_service'],
      grams: current_variant['grams'],
      image_id: current_variant['image_id'],
      inventory_management: current_variant['inventory_management'],
      inventory_policy: current_variant['inventory_policy'],
      weight_unit: current_variant['weight_unit'])
    end
    current['options'].each do |current_option|
      Option.create!(
      site_id: current_option['product_id'], # ID of LINKED product on ellie active
      product_id: prod.id,
      name: current_option['name'],
      position: current_option['position'],
      values: current_option['values'],
      images: current_option['images'],
      image: current_option['image'])
    end
  end
  p 'Active products saved succesfully'
end

def self.delete_all
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    init_stages
  p 'deleting products...'
  STAGING_PRODUCT.each do |current|
    shopify_api_throttle
    ShopifyAPI::Product.delete(current['id'])
  end
  p 'staging products succesfully deleted'
end
end
