require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'active_record'
require 'ruby-progressbar'
Dir['./modules/*.rb'].each { |file| require file }
Dir['./models/*.rb'].each { |file| require file }

# Internal: Automate GET, POST, PUT requests to Ellie.com
# and Elliestaging shopify sites for product metadata cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake productmetafield:save_actives
module ProductMetafieldAPI
  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    sleep 10
  end

  def self.active_to_db
  # Creates an array of all product ids (id field in db)
  # from products table
  # saved into local db to use for metafield GET request loop.
  @product_ids = Product.select('id').all
  ShopifyAPI::Base.site =
    "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
  # creates progress bar because of long method run time
  size = @product_ids.size
  progressbar = ProgressBar.create(
  title: 'Progess',
  starting_at: 0,
  total: size,
  format: '%t: %p%%  |%B|')
  #metafield get request loop
  @product_ids.each do |x|
    current_meta = ShopifyAPI::Metafield.all(params:
     { resource: 'products',
       resource_id: x.id,
       fields: 'namespace, key, value, id, value_type' })
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
        owner_id: x.id)
      end
    end
    progressbar.increment
  end
  p 'active product metafields saved successfully'
  end

  # creates an array of all product_metafields from db
  # iterates through array creating new product_metafields
  # one by one
  def self.db_to_stage
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    @metafields = ProductMetafield.find_by_sql(
      'SELECT product_metafields .*,
       p.title as active_product,
       sp.id as staging_product_id FROM product_metafields
       INNER JOIN products p ON product_metafields.owner_id = p.id
       INNER JOIN staging_products sp ON p.title = sp.title;')
       pp @metafields.count
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
      progressbar.increment
    rescue
      puts "#{current.namespace} metafield failed for #{myprod.title}"
      next
    end
    end
    p 'product_metafields successfully pushed to staging'
  end
end
