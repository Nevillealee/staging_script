require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

module ProductAPI
  # TODO(Neville lee) implement Durrells throttling algorithm
  # set ellie_active_url back to all products endpoint
  #
  ellie_active_url =
  "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/products.json?limit=250"
  @active_product = HTTParty.get(ellie_active_url)

  # saves ellie staging products
  # without variants or options attributes.
  # primary use for cloning active collections
  def self.stage_to_db # STAGING to DB
    ellie_staging_url =
    # GETs 250 products from ellie staging site to save to db
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin/products.json?limit=250"
    @staging_product = HTTParty.get(ellie_staging_url)

    @staging_product["products"].each do |current|
      StagingProduct.create!(title: current["title"],
      body_html: current["body_html"],
      vendor: current["vendor"],
      product_type: current["product_type"],
      handle: current["handle"],
      site_id: current["id"], # product id from ellie active
      template_suffix: current["template_suffix"],
      published_scope: current["published_scope"],
      tags: current["tags"],
      images: current["images"])
    end
    p "Staging products saved succesfully"
  end

  # copies (shallow) active products directly into staging site
  def self.active_to_stage # ACTIVE to STAGING
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

  # pulls active product data from shopify api and saves to
  # database through  active record
  def self.active_to_db # ACTIVE to DB
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
