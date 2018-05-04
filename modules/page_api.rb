require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
require 'ruby-progressbar'
Dir['./models/*.rb'].each { |file| require file }

# Internal: Automate GET, POST, PUT requests to Ellie.com
# and Elliestaging shopify sites for collects cloning
# from active to staging. (See rakelib dir)
#
# Examples
#
#   $ rake page:push_locals
module PageAPI
  ACTIVE_PAGE = []

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
    active_page_count = ShopifyAPI::Collect.count
    nb_pages = (active_page_count / 250.0).ceil
    # Initalize ACTIVE_PAGE with all active collects from Ellie.com
    1.upto(nb_pages) do |page| # throttling conditon
      ellie_active_url =
        "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin/pages.json?limit=250&page=#{page}"
      @parsed_response = HTTParty.get(ellie_active_url)
      # appends each product hash to ACTIVE_PAGE array
      ACTIVE_PAGE.push(@parsed_response['pages'])
      p "active pages set #{page} loaded, sleeping 3"
      sleep 3
    end
    p 'active pages initialized'

    ACTIVE_PAGE.flatten!
  end

  def self.active_to_db
    init_actives
    ACTIVE_PAGE.each do |current|
      Page.create(
        id: current['id'],
        shop_id: current['shop_id'],
        title: current['title'],
        handle: current['handle'],
        body_html: current['body_html'],
        author: current['author'],
        template_suffix: current['template_suffix'])
    end
    p 'Pages succesfully saved'
  end

  def self.db_to_stage
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    @pages = Page.all
    # creates progress bar because of long method run time
    size = @pages.size
    progressbar = ProgressBar.create(
    title: 'Progess',
    starting_at: 0,
    total: size,
    format: '%t: %p%%  |%B|')
    p 'pushing pages to staging.. This may take several minutes...'

    @pages.each do |current|
      shopify_api_throttle
      ShopifyAPI::Page.create(
      title: current.title,
      body_html: current.body_html,
      author: current.author,
      template_suffix: current.template_suffix || "")
      progressbar.increment
    end
    p 'pages successfully pushed to staging'
  end
end
