require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'pp'
require 'active_record'
Dir['./modules/*.rb'].each { |file| require file }
Dir['./models/*.rb'].each { |file| require file }

module ArticleAPI
  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    return if ShopifyAPI.credit_left > 5
    p 'api limit reached, sleeping 10'
    sleep 10
  end

  def self.active_to_db
    ShopifyAPI::Base.site =
      "https://#{ENV['ACTIVE_API_KEY']}:#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
    @current_blogs = Blog.all

    @current_blogs.each do |current|
      articles = ShopifyAPI::Article.find(:all, blog_id: current.id )
      articles.each do |art|
        Article.find_or_initialize_by(id: art.id).update(art.attributes)
        Article.find_or_initialize_by(id: art.id).update(blog_id: art.blog_id)
      end
    end
    p 'active articles saved successfully'
  end

  def self.db_to_stage
    @staging_articles = Article.find_by_sql(
      "SELECT articles.*, sb.id as staging_blog_id,
      sb.title as staging_blog_title,
      b.title as blog_title from articles
      INNER JOIN blogs b ON articles.blog_id = b.id
      INNER JOIN staging_blogs sb ON sb.title = b.title;")

      p 'staging_articles initialized...'

      @staging_articles.each do |current|
        shopify_api_throttle
        auth = {:username => ENV['STAGING_API_KEY'], :password => ENV['STAGING_API_PW'] }
        HTTParty.post("https://elliestaging.myshopify.com/admin/blogs/#{current['staging_blog_id']}/articles.json",
          body: { article: {
            title: current['title'],
            author: current['author'],
            body_html: current['body_html'],
            tags: current['tags'],
            summary_html: current['summary_html'],
            handle: current['handle'],
            image: current['image'],
            published_at: current['published_at'],
            created_at: current['created_at'],
            updated_at: current['updated_at'],
            published: current['published'],
            template_suffix: current['template_suffix']
            } }.to_json, headers: { 'Content-Type' => 'application/json' },
          basic_auth: auth )
          p "pushed #{current['title']}"
      end
    p 'successfully pushed articles to ellie staging...'
  end
end
