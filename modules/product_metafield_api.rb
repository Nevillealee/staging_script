require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'ruby-progressbar'
Dir['./modules/*.rb'].each { |file| require file }
Dir['./models/*.rb'].each { |file| require file }

# Internal: Automate GET, POST, PUT requests to ellie.com
# and elliestaging shopify sites for product metadata cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake productmetafield:save_actives
module ProductMetafieldAPI
  def self.shopify_api_throttle
    return if ShopifyAPI.credit_left > 5
    puts "credit limited reached, sleepng 10..."
    sleep 5
  end

  def self.active_to_db
  active_key = ENV['ACTIVE_API_KEY']
  active_pw = ENV['ACTIVE_API_PW']
  active_shop = ENV['ACTIVE_SHOP']
  active_url =
    "https://#{active_key}:#{active_pw}@#{active_shop}.myshopify.com/admin"

  @product_ids = Product.select('id').all
  ShopifyAPI::Base.site = active_url
  size = @product_ids.size
  progressbar = ProgressBar.create(
  title: 'Progess',
  starting_at: 0,
  total: size,
  format: '%t: %p%%  |%B|')
  begin
    shopify_api_throttle
    @product_ids.each do |x|
      current_meta = ShopifyAPI::Metafield.all(params:
       { resource: 'products',
         resource_id: "#{x.id}",
         fields: 'namespace, key, value, id, value_type'
        })

      if !current_meta.nil? && current_meta[0]
        if current_meta[0].namespace != 'EWD_UFAQ' &&
          ShopifyAPI::CustomCollection.find(:all, params: { product_id: x.id })
          # save current validated metafield to db
          ProductMetafield.create(
            id: current_meta[0].id,
            namespace: current_meta[0].namespace,
            key: current_meta[0].key,
            value: current_meta[0].value,
            value_type: current_meta[0].value_type,
            owner_id: x.id
          )
          puts "saved #{x.id}"
        end
      end
      progressbar.increment
    rescue StandardError => e
      puts "#{x.id}"
      puts e.inspect
    end
      p 'active product metafields saved successfully'
    end
  end

  def self.db_to_stage
    stage_key = ENV['STAGING_API_KEY']
    stage_pw = ENV['STAGING_API_PW']
    stage_shop = ENV['STAGING_SHOP']
    stage_url =
      "https://#{stage_key}:#{stage_pw}@#{stage_shop}.myshopify.com/admin"
    ShopifyAPI::Base.site = stage_url

    @metafields = ProductMetafield.find_by_sql(
      "SELECT product_metafields.*,
       p.title as active_product,
       sp.id as staging_product_id
       FROM product_metafields
       INNER JOIN products p ON product_metafields.owner_id = p.id
       INNER JOIN staging_products sp ON LOWER(p.title) = LOWER(sp.title);")
       puts "#{@metafields.size} Metafields to process"
    # creates progress bar because of long method run time
    size = @metafields.size
    progressbar = ProgressBar.create(
    title: 'Progess',
    starting_at: 0,
    total: size,
    format: '%t: %p%%  |%B|')

    p 'pushing product_metafields to staging.. This may take several minutes...'
    @metafields.each do |current|
      begin
      ProductMetafieldAPI.shopify_api_throttle
      myprod = ShopifyAPI::Product.find(current.staging_product_id)
      myprod.add_metafield(ShopifyAPI::Metafield.new(
      namespace: current.namespace,
      key: current.key,
      value: current.value,
      value_type: current.value_type ))
      myprod.save
    rescue
      puts "#{current.namespace} metafield failed for #{myprod.title}"
      next
    end
    progressbar.increment
    end
    p 'product_metafields successfully pushed to staging'
  end

  def self.update_staging
    stage_key = ENV['STAGING_API_KEY']
    stage_pw = ENV['STAGING_API_PW']
    stage_shop = ENV['STAGING_SHOP']
    stage_url =
      "https://#{stage_key}:#{stage_pw}@#{stage_shop}.myshopify.com/admin"
    ShopifyAPI::Base.site = stage_url

    @metafields = ProductMetafield.find_by_sql(
      "SELECT product_metafields.*,
       p.title as active_product,
       sp.id as staging_product_id
       FROM product_metafields
       INNER JOIN products p ON product_metafields.owner_id = p.id
       INNER JOIN staging_products sp ON p.handle = sp.handle
       where product_metafields.namespace = 'ellie_order_info';")
       puts "#{@metafields.size} Metafields to process"
    # creates progress bar because of long method run time
    size = @metafields.size
    progressbar = ProgressBar.create(
    title: 'Progess',
    starting_at: 0,
    total: size,
    format: '%t: %p%%  |%B|')

    p 'pushing product_metafields to staging.. This may take several minutes...'
    @metafields.each do |current|
      begin
      shopify_api_throttle
      myprod = ShopifyAPI::Product.find(current.staging_product_id)
      myprod.add_metafield(ShopifyAPI::Metafield.new(
      namespace: current.namespace,
      key: current.key,
      value: current.value,
      value_type: current.value_type ))
      myprod.save
      puts "#{myprod.title} metafield updated"
      rescue
        puts "#{current.namespace} metafield failed for #{myprod.title}"
        next
      end
    progressbar.increment
    end
    p 'product_metafields successfully pushed to staging'
  end
end
