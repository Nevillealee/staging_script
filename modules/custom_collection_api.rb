# Internal: Automate GET, POST, PUT requests to ellie.com
# and elliestaging shopify sites for custom collection cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake customcollection:save_actives
require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

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

    # Initalize ACTIVE_COLLECTION with all active custom collections from ellie.com
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
      next if StagingCustomCollection.exists?(handle: current['handle'])
      puts "new staging collection: #{current['title']}"
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
      published_scope: current.published_scope
    )
      puts current.title
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

  def self.delete_dups
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    dup_collections = StagingCustomCollection.find_by_sql(
      "SELECT * from staging_custom_collections where handle like '%-_' or handle like '%-__';"
    )
    p 'deleting duplicate Custom Collections...'
    dup_collections.each do |current|
      puts "#{current['handle']} deleted"
      shopify_api_throttle
      ShopifyAPI::CustomCollection.delete(current['id'])
    end
    p 'duplicate staging custom collections succesfully deleted'
  end

  # appends month YY exclusives to July 18 exclusives
  def self.append_exclusives
    ShopifyAPI::Base.site =
    "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    # "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    origin_id = '83443056698'
    destination_id = '85077459002'
    my_url = "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/products.json?collection_id=#{origin_id}&limit=250"
    @parsed_response = HTTParty.get(my_url)
    prod_array = @parsed_response['products']
    prod_array.each do |p|
      begin
        shopify_api_throttle
      ShopifyAPI::Collect.create(
        product_id: p["id"],
        collection_id: destination_id
      )
      puts "#{p["title"]} added"
    rescue => e
      puts "#{e.message} on #{p['id']}"
      next
    end
    end
  end

  # adds tags to all products in given collection
  def self.add_product_tags
    active_url =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    staging_url =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    # marika_active = "https://91ed9a464305ecb03ee1e20282e39b41:483fc89937bb3a4a7edc85b25e18e347@marikaactive.myshopify.com/admin"
    collection_id = '90052427834'
    new_tag = 'ellie-exclusive'

    ShopifyAPI::Base.site = active_url
    my_endpoint = active_url + "/products.json?collection_id=#{collection_id}&limit=250"
    @parsed_response = HTTParty.get(my_endpoint)
    prod_array = @parsed_response['products']

    prod_array.each do |prod_value|
      p = ShopifyAPI::Product.find(prod_value['id'])
      begin
        shopify_api_throttle
        my_tags = p.tags.split(",")
        my_tags.map! {|x| x.strip}
        puts "#{p.title} tags before: #{my_tags.inspect}"

        if my_tags.exclude?(new_tag)
          my_tags << new_tag
          p.tags = my_tags.join(",")
          p.save!
          puts "#{p.title} tags now: #{my_tags.inspect}"
        end
      rescue => e
        puts "#{e.message} on #{p.id}"
        next
      end
    end
    puts "tagging complete..."
  end

  # adds tags to all products in given collection
  def self.remove_product_tags
    # active_url =
    #   "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    # staging_url =
    #   "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"

    collection_id = '84205011062'


    ShopifyAPI::Base.site = marika_active
    my_endpoint = marika_active + "/products.json?collection_id=#{collection_id}&limit=250"
    my_tag = 'final_sale'

    @parsed_response = HTTParty.get(my_endpoint)
    prod_array = @parsed_response['products']

    prod_array.each do |prod_obj|
      p = ShopifyAPI::Product.find(prod_obj['id'])
      begin
        shopify_api_throttle
        my_tags = p.tags.split(",")
        my_tags.map! {|x| x.strip}
        puts "#{p.title} tags before: #{my_tags.inspect}"

        my_tags.each do |t|
          if t.include?(my_tag)
            my_tags.delete(t)
          end
        end
        p.tags = my_tags.join(",")
        p.save!
        puts "#{p.title} tags after: #{my_tags.inspect}"
      rescue => e
        puts "#{e.message} on #{p.id}"
        next
      end
    end
    puts "tagging complete..."
  end

end
