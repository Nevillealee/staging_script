require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'ruby-progressbar'
Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }

# Internal: Automate GET, POST, PUT requests to marika.com
# and marikastaging shopify sites for products cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake product:save_stages
module ProductAPI
  ACTIVE_PRODUCT = []
  STAGING_PRODUCT = []

  def self.shopify_api_throttle
      return if ShopifyAPI.credit_left > 5
      puts "credit limit reached, sleeping 10..."
    sleep 10
  end

  def self.init_actives
    my_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = my_url
    active_product_count = ShopifyAPI::Product.count
    nb_pages = (active_product_count / 250.0).ceil

    # Initalize ACTIVE_PRODUCT with all active products from marika.com
    1.upto(nb_pages) do |page| # throttling conditon
      marika_active_url = my_url + "/products.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(marika_active_url)

      ACTIVE_PRODUCT.push(@parsed_response['products'])
      p "active products set #{page}/#{nb_pages} loaded, sleeping 3"
      sleep 3
    end
    p 'active products initialized'

    ACTIVE_PRODUCT.flatten!
  end

  def self.init_stages
    my_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    ShopifyAPI::Base.site = my_url
    staging_product_count = ShopifyAPI::Product.count
    nb_pages = (staging_product_count / 250.0).ceil
    puts "initializing Marika staging products"

    # Initalize @STAGING_PRODUCT with all staging products from marikastaging
    1.upto(nb_pages) do |page|
      marika_staging_url = my_url + "/products.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(marika_staging_url)
      STAGING_PRODUCT.push(@parsed_response['products'])
      p "staging products set #{page}/#{nb_pages} loaded, sleeping 3"
      sleep 3
    end
    p 'staging products initialized'
    STAGING_PRODUCT.flatten!
  end

  # saves marika staging products
  # without variants or options attributes.
  # primary use for cloning active collections
  def self.stage_to_db
    init_stages
    p 'saving staging products...'

    STAGING_PRODUCT.each do |current|
      begin
        StagingProduct.create(
        title: current['title'],
        id: current['id'],
        body_html: current['body_html'],
        vendor: current['vendor'],
        product_type: current['product_type'],
        handle: current['handle'],
        template_suffix: current['template_suffix'] || '',
        published_scope: current['published_scope'],
        tags: current['tags'],
        images: current['images'],
        variants: current['variants'],
        options: current['options'],
        image: current['image'],
        created_at: current['created_at'],
        updated_at: current['updated_at'])
      rescue
        puts "error with #{current['title']}"
        next
      end
    end
    p 'staging products saved to db'
  end

  # Internal: pushes active_products hash array (HTTParty response)
  # to marikastaging. Duplicate handles wont push to shopify
  # All methods are module methods and should be
  # called on the ProductAPI module.
  #
  # Examples
  #
  #   ProductAPI.active_to_stage
  #   #=> pushing products to shopify...
  #   #=> saved [product title]
def self.active_to_stage
  init_actives
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  p 'transferring active products to staging...'

  ACTIVE_PRODUCT.each do |current|
    ProductAPI.shopify_api_throttle
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
     image: current['image'],
     created_at: current['created_at'],
     updated_at: current['updated_at'])
   rescue
     p "error with #{current['title']}"
     next
   end
  end
  p 'transfer complete'
end
# Internal: pushes active_products table to marikastaging
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
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
  # updates staging with products on marika that arent on staging according to tables
  product = Product.find_by_sql(
      "SELECT products.* from products
      LEFT JOIN staging_products
      ON products.handle = staging_products.handle
      WHERE staging_products.handle is null
      AND products.title not like '%Auto renew%';"
    )
  # Product.all

  p 'pushing products to shopify...'

  product.each do |current|
    begin
    ProductAPI.shopify_api_throttle
    ShopifyAPI::Product.create!(
     title: current['title'],
     vendor: current['vendor'],
     body_html: current['body_html'] || "",
     handle: current['handle'],
     product_type: current['product_type'] || "",
     template_suffix: current['template_suffix'] || "",
     images: current['images'] || "",
     image: current['image'] || "",
     tags: current['tags'],
     created_at: current['created_at'],
     updated_at: current['updated_at'])

  # pull down product just created with its new staging id
   staging_product = ShopifyAPI::Product.find(:all, params: {handle: current['handle']})

   myid = staging_product[0].attributes["id"]
   staging_product[0].attributes['variants'].clear
   # copy each variant from db table into hashes
   # to push up with staging product via its variant array
   staging_product[0].attributes['options'].clear
   current.options.each do |x|
    hash_opt =  ShopifyAPI::Option.new(
      "name"=> x.name,
      "position"=> x.position,
      "values"=> x.values
    )
    hash_opt.prefix_options = { product_id: myid }
    staging_product[0].attributes['options'].push(hash_opt)
   end

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
      "option2"=> x.option2,
      "barcode"=> x.barcode,
      "grams"=> x.grams,
      # "image_id"=> x.image_id,
      "inventory_quantity" => x.inventory_quantity,
      "weight_unit"=> x.weight_unit
    )
    # linked product_id lives in prefix_options key not attributes!
    hash_var.prefix_options = { product_id: myid }
    staging_product[0].attributes['variants'].push(hash_var)
   end
   staging_product[0].save
   puts "saved #{staging_product[0].attributes['title']} with variants/options"
   # puts staging_product[0].inspect
 rescue StandardError => e
       puts e.inspect
       p "error with #{current.title}"
       next
     end
   # p "#{current['title']} saved with variants"
  end
  puts "products pushed to staging"
end

# Internal: Update marika staging product images
# All methods are module methods and should be
# called on the ProductAPI module.
#
# Examples
#
#   ProductAPI.stage_update
#   #=> updated '[product title]'s images
def self.stage_inventory_update
  puts "updating product attributes.."
  init_actives
  ShopifyAPI::Base.clear_session
  ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
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
    staging_prod = ShopifyAPI::Product.find(:first, params: { title: current['title'] })
    if (staging_prod)
      staging_prod.variants.each do |vrnt|
        my_title = vrnt.attributes["title"]
        my_qty = vrnt.attributes["inventory_quantity"]
        if my_qty <= 0
          my_qty = Variant.find_by(title: my_title)['inventory_quantity']
        end
      end
      staging_prod.save
      puts "#{staging_prod.attributes['title']} saved"
    end
      progressbar.increment
    end
  rescue StandardError => e
    puts "error on #{current['title']}"
    puts "#{e.inspect}"
    sleep 2
    next
  end
    p "Process complete.."
  end

# Internal: saves marika.com products locally to pg database
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
      variants: current['variants'],
      image: current['image'],
      created_at: current['created_at'],
      updated_at: current['updated_at'])

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

# Internal: Deletes all marika staging products
# All methods are module methods and should be
# called on the ProductAPI module.
#
# Examples
#
#   ProductAPI.delete_all
#   #=> staging products succesfully deleted
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

# Internal: tags all products within a given collection
def self.tag_collection_products(collection_id)
  ShopifyAPI::Base.site =
    "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
  @id = collection_id
  my_url =
    "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/products.json?collection_id=#{@id}&limit=250"
  @parsed_response = HTTParty.get(my_url)
  my_products = @parsed_response['products']
  my_products.each do |x|
    shopify_api_throttle
    og_prod = ShopifyAPI::Product.find(x["id"])
    new_tags = og_prod.tags.split(",")
    if new_tags.include?("#{og_prod.product_type}")
      puts "#{og_prod.title} wasnt tagged"
    else
      new_tags.map! {|t| t.strip}
      new_tags << "#{og_prod.product_type}"
      og_prod.tags = new_tags.join(",")
      og_prod.save
      puts "saved #{og_prod.title}"
    end
  end
end

def self.set_staging_availability
  puts "starting set_staging_availability.."
  my_products = StagingProduct.all
  puts "products to check: #{my_products.size}"
  pass_count = 0
  fail_count = 0
  my_products.each do |prod|
    set_true = true
    if prod.variants.size >= 1
      prod.variants.each do |var|
        next unless var['inventory_quantity'] == 0
        puts "FAILED #{prod.title} inventory count= #{var['title']}: #{var['inventory_quantity']}"
        fail_count = fail_count + 1
        set_true = false
      end
      prod.available = true if set_true
      prod.save!
      pass_count = pass_count + 1
    end
  end
  puts "product availablility setting complete!"
  puts "Passed: #{pass_count}, Failed: #{fail_count}"
end

def self.set_active_availability
  puts "starting set_staging_availability.."
  my_products = Product.all
  puts "products to check: #{my_products.size}"
  pass_count = 0
  fail_count = 0
  my_products.each do |prod|
    set_true = true
    if prod.variants.size >= 1
      prod.variants.each do |var|
        if var['inventory_quantity'] == 0
          puts "FAILED #{prod.title} inventory count= #{var['title']}: #{var['inventory_quantity']}"
          set_true = false
          prod.available = 0
          prod.save!
          fail_count = fail_count + 1
        else
          set_true = true
        end
      end
      if set_true
        puts "#{prod.title} passed! vars=#{prod.variants.inspect}"
        prod.available = true
        pass_count = pass_count + 1
        prod.save!
      end
    elsif prod.variants.size == 0
      set_true = false
      prod.available == false
      prod.save!
      fail_count = fail_count + 1
    end
  end
  puts "product availablility setting complete!"
  puts "Passed: #{pass_count}, Failed: #{fail_count}"
end

end
