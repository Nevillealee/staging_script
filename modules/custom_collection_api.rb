require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

# automation suite tranfers data from active ellie
# site, parses JSON responses, and POSTs to staging
# ellie site for testing
module CustomCollectionAPI
  ######################################################
  ACTIVE_COLLECTION = []
  STAGING_COLLECTION = []

  def self.initialize_actives
    ShopifyAPI::Base.site =
    "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin"
    active_custom_collection_count = ShopifyAPI::CustomCollection.count
    nb_pages = (active_custom_collection_count/250.0).ceil

    # Initalize ACTIVE_COLLECTION with all active custom collections from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url =
      "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@#{ENV["ACTIVE_SHOP"]}.myshopify.com/admin/custom_collections.json?limit=250&page=#{page}"
      @parsed_response = (HTTParty.get(ellie_active_url))
      # appends each product hash to ACTIVE_COLLECTION array
      ACTIVE_COLLECTION.push(@parsed_response["custom_collections"])
      p "active custom collections set #{page} loaded, sleeping 3"
      sleep 3
    end
      p "active custom collections initialized"
      # combine hash arrays from each page
      # into single product array
      ACTIVE_COLLECTION.flatten!
  end

  def self.initialize_stages
    ShopifyAPI::Base.site =
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    staging_custom_collection_count = ShopifyAPI::CustomCollection.count
    nb_pages = (staging_custom_collection_count/250.0).ceil

    # Initalize STAGING_COLLECTION with all staging custom collections from elliestaging
    1.upto(nb_pages) do |page|
      ellie_staging_url =
      "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin/custom_collections.json?limit=250&page=#{page}"
      @parsed_response = (HTTParty.get(ellie_staging_url))
      # appends each product hash to @STAGING_COLLECTION array
      STAGING_COLLECTION.push(@parsed_response["custom_collections"])
      p "staging custom collections set #{page} loaded, sleeping 3"
      sleep 3
    end
      p "staging custom collections initialized"
      # combine hash arrays from each page
      # into single product array
      STAGING_COLLECTION.flatten!
  end
  ######################################################

  def self.stage_to_db # STAGING to DB
    self.initialize_stages

    STAGING_COLLECTION.each do |current|
      StagingCustomCollection.create!(site_id: current["id"],
      handle: current["handle"],
      title: current["title"],
      body_html: current["body_html"],
      sort_order: current["sort_order"],
      template_suffix: current["template_suffix"],
      published_scope: current["published_scope"])
    end
    p "Staging Custom Collections saved succesfully"
  end

  #TODO(Neville Lee): THROTTLING ALGORITHM
  def self.db_to_stage # DB to STAGING
    ShopifyAPI::Base.site =
    "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@#{ENV["STAGING_SHOP"]}.myshopify.com/admin"
    # grabs title of each custom collection to use as paramter for new
    # custom collection object created in POST request
    # to staging sight using ShopifyAPI gem
    cc = CustomCollection.all
    cc.each do |current|
      ShopifyAPI::CustomCollection.create!(title: current.title,
      body_html: current.body_html,
      sort_order: current.sort_order,
      template_suffix: current.template_suffix,
      published_scope: current.published_scope)
    end
    p "transfer complete"
  end

  def self.active_to_db # ACTIVE to DB
  self.initialize_actives
  
    ACTIVE_COLLECTION.each do |current|
      CustomCollection.create!(site_id: current["id"],
      handle: current["handle"],
      title: current["title"],
      body_html: current["body_html"],
      sort_order: current["sort_order"],
      template_suffix: current["template_suffix"],
      published_scope: current["published_scope"])
    end
    p "Custom Collections saved succesfully"
  end

  # prints custom collection keys arguement
  def self.printKeys(key)
     ACTIVE_COLLECTION.each do |x|
      p x[key]
    end
  end
  # prints all custom_collections from active site
  def self.print
    ACTIVE_COLLECTION.each do |x|
      pp x
   end
  end
end
