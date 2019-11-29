# Internal: Automate GET, POST, PUT requests to Ellie.com
# and Elliestaging shopify sites for products cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake product:save_stages
require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'ruby-progressbar'

Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }

module ProductAPI
  ACTIVE_PRODUCT = []
  STAGING_PRODUCT = []

  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}"\
      "@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      return if ShopifyAPI.credit_left > 5
      puts "limit reached sleeping 5"
    sleep 5
  end

  def self.init_actives
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}"\
      "@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    active_product_count = ShopifyAPI::Product.count
    nb_pages = (active_product_count / 250.0).ceil

    # Initalize ACTIVE_PRODUCT with all active products from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url = "https://#{ENV['ACTIVE_API_KEY']}:"\
      "#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/"\
      "admin/products.json?limit=250&page=#{page}"

      @parsed_response = HTTParty.get(ellie_active_url)
      ACTIVE_PRODUCT.push(@parsed_response['products'])
      p "active products set #{page} loaded"
    end
    p 'active products initialized'

    ACTIVE_PRODUCT.flatten!
  end
  def self.init_stages
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}"\
      "@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    staging_product_count = ShopifyAPI::Product.count
    nb_pages = (staging_product_count / 250.0).ceil

    # Initalize @STAGING_PRODUCT with all staging products from elliestaging
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_staging_url =
        "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}"\
        "@#{ENV['STAGING_SHOP']}.myshopify.com/"\
        "admin/products.json?limit=250&page=#{page}"

      @parsed_response = HTTParty.get(ellie_staging_url)
      STAGING_PRODUCT.push(@parsed_response['products'])
      p "staging products set #{page} loaded"
    end
    p 'staging products initialized'
    STAGING_PRODUCT.flatten!
  end

  # saves ellie staging products
  # without variants or options attributes.
  # primary use for cloning active collections
  def self.stage_to_db
    init_stages
    p 'saving staging products...'

    STAGING_PRODUCT.each do |current|
      next if StagingProduct.exists?(handle: current['handle'])
      puts "new staging product: #{current['title']}"
      begin
        StagingProduct.create!(
        title: current['title'],
        id: current['id'],
        body_html: current['body_html'],
        vendor: current['vendor'],
        product_type: current['product_type'],
        handle: current['handle'],
        template_suffix: current['template_suffix'],
        published_scope: current['published_scope'],
        tags: current['tags'],
        images: current['images'],
        variants: current['variants'],
        options: current['options'],
        image: current['image'],
        created_at: current['created_at'],
        updated_at: current['updated_at'])
      rescue StandardError => e
        puts "error with #{current['title']}"
        print e.messages
        next
      end
    end
    p 'staging products saved to db'
  end

  # Internal: pushes active_products hash array (HTTParty response)
  # to elliestaging. Duplicate handles wont push to shopify
  # All methods are module methods and should be
  # called on the ProductAPI module.
  #
  # Examples
  #
  #   ProductAPI.active_to_stage
  #   #=> pushing products to shopify...
  #   #=> saved [product title]
def self.active_to_stage
  # init_actives
  # ShopifyAPI::Base.site =
  #   "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}"\
  #   "@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  # p 'transferring active products to staging...'
  #
  # ACTIVE_PRODUCT.each do |current|
  #   ProductAPI.shopify_api_throttle
  #   begin
  #     ShopifyAPI::Product.create(
  #    title: current['title'],
  #    vendor: current['vendor'],
  #    body_html: current['body_html'],
  #    handle: current['handle'],
  #    product_type: current['product_type'],
  #    template_suffix: current['template_suffix'] || "",
  #    variants: current['variants'],
  #    options: current['options'],
  #    images: current['images'],
  #    image: current['image'],
  #    created_at: current['created_at'],
  #    updated_at: current['updated_at'])
  #   rescue
  #    p "error with #{current['title']}"
  #    next
  #   end
  # end
  p 'depreciated method, use product:db_to_stage'
end
# Internal: pushes active_products table to elliestaging
# All methods are module methods and should be
# called on the ProductAPI module.
#
# Examples
#
#   ProductAPI.db_to_stage
#   #=> pushing products to shopify...
#   #=> saved [product title]
def self.db_to_stage
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:"\
    "#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  # updates staging with new products from ellie.com
  product = Product.find_by_sql(
    "SELECT products.* from products
    LEFT JOIN staging_products
    ON products.handle = staging_products.handle
    WHERE staging_products.handle is NULL
    AND products.title not like '%Auto renew%';"
  )

  p 'pushing products to shopify...'
  product.each do |current|
    ProductAPI.shopify_api_throttle
    begin
    ShopifyAPI::Product.create(
     title: current['title'],
     vendor: current['vendor'],
     body_html: current['body_html'],
     handle: current['handle'],
     product_type: current['product_type'],
     template_suffix: current['template_suffix'],
     # images: current['images'],
     image: current['image'],
     tags: current['tags'],
     created_at: current['created_at'],
     updated_at: current['updated_at'])
   rescue StandardError => e
      p "error with #{current['title']}"
      p e.inspect
    end

   staging_product = ShopifyAPI::Product.find(
     :all, params: {handle: current['handle']}
   )
   myid = staging_product[0].attributes["id"]
   staging_product[0].attributes['variants'].clear

   current.variants.each do |x|
    hash_var =  ShopifyAPI::Variant.new(
      "title"=> x.title,
      "price"=> x.price,
      "sku"=> x.sku,
      "compare_at_price"=> x.compare_at_price,
      "inventory_policy"=> x.inventory_policy,
      "fulfillment_service"=> x.fulfillment_service,
      "inventory_management"=> x.inventory_management,
      "position"=> x.position,
      "option1"=> x.option1,
      "barcode"=> x.barcode,
      "grams"=> x.grams,
      # "image_id"=> x.image_id,
      "weight_unit"=> x.weight_unit,
    )
    hash_var.prefix_options = { product_id: myid }
    staging_product[0].attributes['variants'].push(hash_var)
   end

   staging_product[0].save
   puts "#{current['title']}"
  end
  puts "products pushed to staging"
end

# Internal: Update ellie staging product images
# All methods are module methods and should be
# called on the ProductAPI module.
#
# Examples
#
#   ProductAPI.stage_update
#   #=> updated '[product title]'s images
def self.stage_attr_update
  init_actives
  ShopifyAPI::Base.clear_session
  ShopifyAPI::Base.site =
  "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}"\
  "@#{ENV['STAGING_SHOP']}.myshopify.com/admin"

  size = ACTIVE_PRODUCT.size
  progressbar = ProgressBar.create(
    title: 'Progess',
    starting_at: 0,
    total: size,
    format: '%t: %p%%  |%B|')
  # ACTIVE_PRODUCT array of hashes

  ACTIVE_PRODUCT.each do |current|
    shopify_api_throttle
    begin
      stage_prod = ShopifyAPI::Product.find(
        :first, params: { handle: current['handle'] }
      )
      stage_prod.images.concat(current['images'])
      stage_prod.image = current['image']
      progressbar.increment
    rescue StandardError => e
      puts "error on #{current['title']}"
      puts e.inspect
      next
    end
  end
  puts "Process complete.."
end

def self.inventory_update
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:"\
    "#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"

    staging_products = StagingProduct.where("created_at > ?", Date.today << 5)
    staging_products.each do |stage_prod|
      ProductAPI.shopify_api_throttle
      begin
        stage_prod['variants'].each do |variant|
          result = Variant.find_by_sql("SELECT variants.* from staging_products s
            INNER JOIN products a ON a.handle = s.handle INNER JOIN variants ON variants.product_id = a.id
            WHERE s.id = #{stage_prod.id} AND variants.title = '#{variant['title']}';"
          )
          active_qty = result[0]['inventory_quantity']
          next unless active_qty.to_i > 0
          params = {inventory_item_ids: variant['inventory_item_id']}
          inventory_item = ShopifyAPI::InventoryLevel.find(:first, params: params)
          inventory_item.set(active_qty)
          puts inventory_item.inspect
        end
      rescue StandardError => e
        puts "#{stage_prod['title']} failed..."
        puts e.inspect
        next
      end
    end



end

# Internal: saves ellie.com products locally to pg database
# All methods are module methods and should be
# called on the ProductAPI module.
#
# Examples
#
#   ProductAPI.active_to_db
#   #=> Active products saved succesfully
def self.active_to_db
  init_actives

  ACTIVE_PRODUCT.each do |current|
    prod = Product.create!(
      id: current['id'],
      title: current['title'],
      body_html: current['body_html'],
      vendor: current['vendor'],
      product_type: current['product_type'],
      handle: current['handle'],
      template_suffix: current['template_suffix'],
      published_scope: current['published_scope'],
      tags: current['tags'],
      images: current['images'],
      image: current['image'],
      created_at: current['created_at'],
      updated_at: current['updated_at'],
    )
    current['variants'].each do |current_variant|
      Variant.create(
      id: current_variant['id'],
      product_id: prod.id,
      title: current_variant['title'],
      option1: current_variant['option1'],
      sku: current_variant['sku'],
      price: current_variant['price'],
      barcode: current_variant['barcode'],
      compare_at_price: current_variant['compare_at_price'],
      fulfillment_service: current_variant['fulfillment_service'],
      grams: current_variant['grams'],
      image_id: current_variant['image_id'],
      inventory_item_id: current_variant['inventory_item_id'],
      inventory_quantity: current_variant['inventory_quantity'],
      inventory_management: current_variant['inventory_management'],
      inventory_policy: current_variant['inventory_policy'],
      weight_unit: current_variant['weight_unit'])
    end
    current['options'].each do |current_option|
      Option.create!(
      id: current_option['id'],
      product_id: prod.id,
      name: current_option['name'],
      position: current_option['position'],
      values: current_option['values'],
      images: current_option['images'],
      image: current_option['image'])
    end
    p "saved #{current['title']}"
  end
  p 'Active products saved succesfully'
end

# Internal: Deletes all duplicate ellie staging products
# All methods are module methods and should be
# called on the ProductAPI module.
#
# Examples
#
#   ProductAPI.delete_dups
#   #=> duplicate staging products succesfully deleted
def self.delete_dups
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  dup_products = StagingProduct.find_by_sql(
    "SELECT * from staging_products where handle like '%-_';"
  )
  p 'deleting duplicate staging products...'
  dup_products.each do |current|
    puts "#{current['handle']} deleted"
    shopify_api_throttle
    ShopifyAPI::Product.delete(current['id'])
  end
  p 'duplicate staging products succesfully deleted'
end

end
