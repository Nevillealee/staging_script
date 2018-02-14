require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

module CollectAPI
  # sets ellie active url to Custom Collections endpoint
  ellie_active_url =
  "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/collects.json?limit=250"
  # GET request for all custom collections from ellieactive shop
  @active_collection = HTTParty.get(ellie_active_url)

  def self.active_to_db # ACTIVE to DB
    @active_collection["collects"].each do |current|
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
    @collect_matches.each do |current|
      ShopifyAPI::Collect.create!(product_id: current["new_p_id"],
       collection_id: current["new_cc_id"])
    end
  end
end
