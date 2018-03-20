require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'

module ArticleAPI
  def self.api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    sleep 10
  end

  def self.active_to_db
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    @current_blogs = Blog.all
    @current_blogs.each do |current|
      # save current article to db
      articles = ShopifyAPI::Article.find(:all, blog_id: current.id )
      articles.each do |art|
        Article.find_or_initialize_by(id: art.id).update(art.attributes)
        Article.find_or_initialize_by(id: art.id).update(blog_id: art.blog_id)
      end
    end
    p 'active articles saved successfully'
  end

  def self.db_to_stage
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    staging_blog_ids = ShopifyAPI::Blog.all(params: {fields: 'id'})
    p 'pushing blogs to ellie staging...'

  end
end
