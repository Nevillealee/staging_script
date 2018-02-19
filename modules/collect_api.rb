require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

module CollectAPI
  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    puts "CREDITS LEFT: #{ShopifyAPI.credit_left}"
    puts "SLEEPING 10"
    sleep 10
  end
  
  ACTIVE_COLLECT = []

  def self.initialize_actives
    ShopifyAPI::Base.site =
    "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin"
    active_collect_count = ShopifyAPI::Collect.count
    nb_pages = (active_collect_count/250.0).ceil

    # Initalize ACTIVE_COLLECT with all active collects from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url =
      "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/collects.json?limit=250&page=#{page}"
      @parsed_response = (HTTParty.get(ellie_active_url))
      # appends each product hash to ACTIVE_PRODUCT array
      ACTIVE_COLLECT.push(@parsed_response["collects"])
      p "active collects set #{page} loaded, sleeping 3"
      sleep 3
    end
      p "active colects initialized"
      # combine hash arrays from each page
      # into single collect array
      ACTIVE_COLLECT.flatten!
  end

  def self.active_to_db # ACTIVE to DB
    self.initialize_actives
    ACTIVE_COLLECT.each do |current|
      Collect.create!(site_id: current["id"],
        collection_id: current["collection_id"],
        featured: current["featured"],
        position: current["position"],
        product_id: current["product_id"])
    end
    p "Collects succesfully saved"
  end

  def self.db_to_stage #DB TO STAGING
    ShopifyAPI::Base.site =
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    # creates an array of active(old) and staging(new)
    # product/custom collection ids objects matched by handle
    @collect_matches = StagingCollect.find_by_sql(
      "SELECT scc.site_id as new_cc_id,
       scc.handle as custom_collection_handle, cc.site_id as old_cc_id,
       sp.site_id as new_p_id,
       sp.handle as product_handle,  p.site_id as old_p_id
       FROM collects c
       INNER JOIN products p ON c.product_id = p.site_id
       INNER JOIN custom_collections cc ON c.collection_id = cc.site_id
       INNER JOIN staging_products sp ON p.handle = sp.handle
       INNER JOIN staging_custom_collections scc ON cc.handle = scc.handle;")
       # creates clone of active collects on ellie staging
       # based on current data in local db
       p 'pushing local collects to staging...'
    @collect_matches.each do |current|
      CollectAPI.shopify_api_throttle
      ShopifyAPI::Collect.create(product_id: current["new_p_id"],
       collection_id: current["new_cc_id"])
    end
    p 'local collects successfully pushed to staging'
  end
end
