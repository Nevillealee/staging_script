require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
# Internal: Automate GET, POST, PUT requests to Ellie.com
# and Elliestaging shopify sites for custom collection cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake customcollection:save_actives
module CustomCollectionAPI
  ACTIVE_COLLECTION = []
  STAGING_COLLECTION = []

  def self.shopify_api_throttle
    return if ShopifyAPI.credit_left > 5
    puts "CREDITS LEFT: #{ShopifyAPI.credit_left}"
    puts 'SLEEPING 10'
    sleep 10
  end

  def self.init_actives
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    active_custom_collection_count = ShopifyAPI::CustomCollection.count
    nb_pages = (active_custom_collection_count / 250.0).ceil

    # Initalize ACTIVE_COLLECTION with all active custom collections from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url =
        "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/custom_collections.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_active_url)
      # appends each product hash to ACTIVE_COLLECTION array
      ACTIVE_COLLECTION.push(@parsed_response['custom_collections'])
      p "active custom collections set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'active custom collections initialized'

    ACTIVE_COLLECTION.flatten!
  end

  def self.init_stages
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    staging_custom_collection_count = ShopifyAPI::CustomCollection.count
    nb_pages = (staging_custom_collection_count / 250.0).ceil
    # Initalize STAGING_COLLECTION with all staging
    # custom collections from elliestaging
    1.upto(nb_pages) do |page|
      ellie_staging_url =
        "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin/custom_collections.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_staging_url)
      # appends each product hash to @STAGING_COLLECTION array
      STAGING_COLLECTION.push(@parsed_response['custom_collections'])
      p "staging custom collections set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'staging custom collections initialized'
    STAGING_COLLECTION.flatten!
  end

  def self.stage_to_db
    init_stages
    STAGING_COLLECTION.each do |current|
      StagingCustomCollection.create!(
      id: current['id'],
      handle: current['handle'],
      title: current['title'],
      body_html: current['body_html'],
      sort_order: current['sort_order'],
      template_suffix: current['template_suffix'],
      published_scope: current['published_scope'],
      updated_at: current['updated_at'],
      created_at: current['created_at']
    )
    end
    p 'Staging Custom Collections saved succesfully'
  end

  def self.db_to_stage
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      # UPDATES CUSTOM COLLECTIONS ONLY
      # change to cc = CustomCollection.all
      # for full migration
    cc = CustomCollection.find_by_sql(
          "SELECT custom_collections.* from custom_collections
          LEFT JOIN staging_custom_collections
          ON custom_collections.handle = staging_custom_collections.handle
          WHERE staging_custom_collections.handle is null;")

    p 'Pushing local Custom Collections to staging...'
    cc.each do |current|
      CustomCollectionAPI.shopify_api_throttle
      ShopifyAPI::CustomCollection.create!(
      title: current.title,
      body_html: current.body_html,
      sort_order: current.sort_order,
      template_suffix: current.template_suffix,
      published_scope: current.published_scope)
    end
    p 'transfer complete'
  end

  def self.active_to_db
    init_actives
    ACTIVE_COLLECTION.each do |current|
      CustomCollection.create(
        id: current['id'],
        handle: current['handle'],
        title: current['title'],
        body_html: current['body_html'],
        sort_order: current['sort_order'],
        template_suffix: current['template_suffix'],
        published_scope: current['published_scope'],
        updated_at: current['updated_at'],
        created_at: current['created_at']
      )
    end
    p 'Custom Collections saved succesfully'
  end

  def self.delete_all
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      init_stages
    p 'deleting Custom Collections...'
    STAGING_COLLECTION.each do |current|
      shopify_api_throttle
      ShopifyAPI::CustomCollection.delete(current['id'])
    end
    p 'staging custom collections succesfully deleted'
  end

  # appends June 18 exclusives to July 18 exclusives
  def self.append_exclusives
    ShopifyAPI::Base.site =
    "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    june18_id = '33208664156'
    july18_id = '57382502492'
    my_url = "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin/products.json?collection_id=#{june18_id}"
    @parsed_response = HTTParty.get(my_url)
    prod_array = @parsed_response['products']

    prod_array.each do |p|
      begin
      ShopifyAPI::Collect.create(
        product_id: p["id"],
        collection_id: july18_id
      )
      puts "#{p["title"]} added"
    rescue => e
      puts "#{e.message} on #{p['id']}"
      next
    end
    end
  end


end
