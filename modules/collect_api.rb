<<<<<<< HEAD
=======
require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'ruby-progressbar'
>>>>>>> 7164481397f7ac87addb02fef8a7fc3d59f96f69
# Internal: Automate GET, POST, PUT requests to marika.com
# and marikastaging shopify sites for collects cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake collect:push_locals
require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
require 'ruby-progressbar'

module CollectAPI
  ACTIVE_COLLECT = []
  STAGING_COLLECT = []

  stage_key = ENV['STAGING_API_KEY']
  stage_pw = ENV['STAGING_API_PW']
  stage_shop = ENV['STAGING_SHOP']
  @stage_url =
    "https://#{stage_key}:#{stage_pw}@#{stage_shop}.myshopify.com/admin"

  active_key = ENV['ACTIVE_API_KEY']
  active_pw = ENV['ACTIVE_API_PW']
  active_shop = ENV['ACTIVE_SHOP']
  @active_url =
    "https://#{active_key}:#{active_pw}@#{active_shop}.myshopify.com/admin"


  def self.shopify_api_throttle
<<<<<<< HEAD
    ShopifyAPI::Base.site = @stage_url
=======
    # ShopifyAPI::Base.site =
    #   "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
>>>>>>> 7164481397f7ac87addb02fef8a7fc3d59f96f69
    return if ShopifyAPI.credit_left > 5
    puts "CREDITS LEFT: #{ShopifyAPI.credit_left}"
    puts 'SLEEPING 10'
    sleep 10
  end

  # Initalize ACTIVE_COLLECT with all active collects from ellie.com
  def self.init_actives
    ShopifyAPI::Base.site = @active_url
    active_collect_count = ShopifyAPI::Collect.count
    nb_pages = (active_collect_count / 250.0).ceil
    1.upto(nb_pages) do |page|
      ellie_active_url = @active_url + "/collects.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_active_url)
      ACTIVE_COLLECT.push(@parsed_response['collects'])
      p "active collects set #{page}/#{nb_pages} loaded, sleeping 3"
      sleep 3
    end
    p 'active collects initialized'
    ACTIVE_COLLECT.flatten!
  end

  # Initalize STAGING_COLLECT with all staging products from elliestaging
  def self.init_stages
    ShopifyAPI::Base.site = @stage_url
    staging_collect_count = ShopifyAPI::Collect.count
    puts "#{staging_collect_count} collects"
    nb_pages = (staging_collect_count / 250.0).ceil
    1.upto(nb_pages) do |page|
      ellie_staging_url = @stage_url + "/collects.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_staging_url)
      STAGING_COLLECT.push(@parsed_response['collects'])
      p "staging collects set #{page}/#{nb_pages} loaded"
    end
    p 'staging collects initialized'
    STAGING_COLLECT.flatten!
  end

  def self.active_to_db
    init_actives
    ACTIVE_COLLECT.each do |current|
      Collect.create(
        id: current['id'],
        collection_id: current['collection_id'],
        featured: current['featured'],
        position: current['position'],
        product_id: current['product_id'],
        updated_at: current['updated_at'],
        created_at: current['created_at']
      )
      puts "saved collect id:#{current['id']}"
    end
    p 'Collects succesfully saved'
  end

  def self.db_to_stage
    ShopifyAPI::Base.site = @stage_url
    # creates an array of active(old) and staging(new)
    # product/custom collection ids objects matched by handle
    @collect_matches = Collect.find_by_sql(
      "SELECT scc.id as new_cc_id, c.position, c.updated_at, c.created_at,
       scc.handle as custom_collection_handle, cc.id as old_cc_id,
       sp.id as new_p_id,
       sp.handle as product_handle,  p.id as old_p_id
       FROM collects c
       INNER JOIN products p ON c.product_id = p.id
       INNER JOIN custom_collections cc ON c.collection_id = cc.id
       INNER JOIN staging_products sp ON p.handle = sp.handle
       INNER JOIN staging_custom_collections scc ON cc.handle = scc.handle;")

       size = @collect_matches.size
       progressbar = ProgressBar.create(
       title: 'Progess',
       starting_at: 0,
       total: size,
       format: '%t: %p%%  |%B|')

    p 'pushing local collects to staging...'
    @collect_matches.each do |current|
      begin
      CollectAPI.shopify_api_throttle
      ShopifyAPI::Collect.create(
        product_id: current['new_p_id'],
        collection_id: current['new_cc_id'],
        position: current['position'],
        updated_at: current['updated_at'],
        created_at: current['created_at']
      )
    rescue
      puts "error with collect id: #{current['id']}"
      next
    end
    progressbar.increment
    end
    p 'local collects successfully pushed to staging'
  end

  def self.delete_all
    mykey = ENV['STAGING_API_KEY']
    mypw = ENV['STAGING_API_PW']
    shop = ENV['STAGING_SHOP']
    ShopifyAPI::Base.site =
      "https://#{mykey}:#{mypw}@#{shop}.myshopify.com/admin"
      init_stages
    p 'deleting collects...'
    STAGING_COLLECT.each do |current|
      shopify_api_throttle
      begin
      ShopifyAPI::Collect.delete(current['id'])
    rescue
      puts "smart collection error with id: #{current['id']}"
      next
    end
    puts "deleted #{current['id']}"
    end
    p 'staging collects succesfully deleted'
  end


end
