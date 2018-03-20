require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

module BlogAPI
  ACTIVE_BLOG = []
  STAGING_BLOG = []

  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    sleep 10
  end

  def self.init_actives
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    active_blog_count = ShopifyAPI::Blog.count
    nb_pages = (active_blog_count / 250.0).ceil

    # Initalize ACTIVE_BLOG with all active blogs from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url =
        "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/blogs.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_active_url)
      # appends each blog hash to ACTIVE_BLOG array
      ACTIVE_BLOG.push(@parsed_response['blogs'])
      p "active blogs set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'active blogs initialized'
    # combine hash arrays from each page
    # into single product array
    ACTIVE_BLOG.flatten!
  end

  def self.init_stages
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    staging_blog_count = ShopifyAPI::Blog.count
    nb_pages = (staging_blog_count / 250.0).ceil

    # Initalize STAGING_BLOG with all staging blogs from elliestaging.myshopify.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_staging_url =
        "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin/blogs.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_staging_url)
      # appends each blog hash to STAGING_BLOG array
      STAGING_BLOG.push(@parsed_response['blogs'])
      p "staging blogs set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'staging blogs initialized'
    # combine hash arrays from each page
    # into single product array
    STAGING_BLOG.flatten!
  end

  def self.active_to_db
    init_actives
    p 'calling pull blogs'
    ACTIVE_BLOG.each do |object|
      p "saving: #{object['title']}"
      Blog.find_or_initialize_by(id: object['id']).update(object)
    end
    p 'task complete'
  end

  def self.stage_to_db
    init_stages
    p 'calling pull blogs'
    STAGING_BLOG.each do |object|
      p "saving: #{object['title']}"
      StagingBlog.find_or_initialize_by(id: object['id']).update(object)
    end
    p 'task complete'
  end

  def self.db_to_stage
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    blog = Blog.all
    p 'pushing blogs to ellie staging...'
    blog.each do |current|
      shopify_api_throttle
      ShopifyAPI::Blog.create(
       title: current['title'],
       commentable: current['commentable'] || "",
       feedburner: current['feedburner'] || "",
       handle: current['handle'] || "",
       feedburner_location: current['feedburner_location'] || "",
       template_suffix: current['template_suffix'] || "",
       tags: current['tags'] || "")
       p "pushed #{current['title']} blog"
    end
  end
end
