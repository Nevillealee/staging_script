require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
# Internal: Automate GET, POST, PUT requests to Ellie.com
# and Elliestaging shopify sites for collects cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake collect:push_locals
module CollectAPI
  ACTIVE_COLLECT = []
  STAGING_COLLECT = []

  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    puts "CREDITS LEFT: #{ShopifyAPI.credit_left}"
    puts 'SLEEPING 10'
    sleep 10
  end

  def self.init_actives
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    active_collect_count = ShopifyAPI::Collect.count
    nb_pages = (active_collect_count / 250.0).ceil
    # Initalize ACTIVE_COLLECT with all active collects from Ellie.com
    1.upto(nb_pages) do |page|
      ellie_active_url =
        "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/collects.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_active_url)
      ACTIVE_COLLECT.push(@parsed_response['collects'])
      p "active collects set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'active collects initialized'

    ACTIVE_COLLECT.flatten!
  end

  def self.init_stages
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    staging_collect_count = ShopifyAPI::Collect.count
    nb_pages = (staging_collect_count / 250.0).ceil
    # Initalize @STAGING_COLLECT with all staging products from elliestaging
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_staging_url =
        "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin/collects.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_staging_url)
      # appends each product hash to STAGING_PRODUCT array
      STAGING_COLLECT.push(@parsed_response['collects'])
      p "staging collects set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'staging collects initialized'
    STAGING_COLLECT.flatten!
  end

  def self.active_to_db
    init_actives
    ACTIVE_COLLECT.each do |current|
      Collect.create!(
        id: current['id'],
        collection_id: current['collection_id'],
        featured: current['featured'],
        position: current['position'],
        product_id: current['product_id'])
    end
    p 'Collects succesfully saved'
  end

  def self.db_to_stage
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    # creates an array of active(old) and staging(new)
    # product/custom collection ids objects matched by handle
    @collect_matches = Collect.find_by_sql(
      "SELECT scc.id as new_cc_id,
       scc.handle as custom_collection_handle, cc.id as old_cc_id,
       sp.id as new_p_id,
       sp.handle as product_handle,  p.id as old_p_id
       FROM collects c
       INNER JOIN products p ON c.product_id = p.id
       INNER JOIN custom_collections cc ON c.collection_id = cc.id
       INNER JOIN staging_products sp ON p.handle = sp.handle
       INNER JOIN staging_custom_collections scc ON cc.handle = scc.handle;")

    p 'pushing local collects to staging...'
    @collect_matches.each do |current|
      CollectAPI.shopify_api_throttle
      ShopifyAPI::Collect.create(
        product_id: current['new_p_id'],
        collection_id: current['new_cc_id'])
    end
    p 'local collects successfully pushed to staging'
  end

  def self.delete_all
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      init_stages
    p 'deleting products...'
    STAGING_COLLECT.each do |current|
      shopify_api_throttle
      ShopifyAPI::Collect.delete(current['id'])
    end
    p 'staging collects succesfully deleted'
  end
end
