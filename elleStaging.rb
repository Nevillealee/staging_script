require 'httparty'
require 'dotenv/load'
# automation suite GETs data from active ellie
# site, parses JSON responses, and POSTs to staging
# ellie site for testing
module CustomCollection
  # sets ellie active url to all Custom Collections endpoint
  ellie_active_url = "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@ellieactive.myshopify.com/admin/custom_collections.json"
  # GET request for all custom collections from ellieactive shop
  @response = HTTParty.get(ellie_active_url)

  def self.print
    p @response.body
  end

  def self.post_to_staging
    ellie_staging_url = "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@elliestaging.myshopify.com/admin/custom_collections.json"
    options = @response.body["custom_collections"][0]
    if HTTParty.post(ellie_staging_url, options)
      p "success"
    else
      p "unsuccessful"
    end
  end
end

module Product
  # sets ellie active url to all products endpoint
  ellie_active_url = "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@ellieactive.myshopify.com/admin/products.json?"
  # GET request for all active products
  @response = HTTParty.get(ellie_active_url)

  def self.print
    p @response.body
  end

  def self.post_to_staging
    ellie_staging_url = "https://#{ENV["STAGING_API_KEY"]}:#{ENV["STAGING_API_PW"]}@elliestaging.myshopify.com/admin/products.json"
    p @response
  end
end

module Collect
  # sets ellie active url to all collects endpoint
  ellie_active_url = "https://#{ENV["ACTIVE_API_KEY"]}:#{ENV["ACTIVE_API_PW"]}@ellieactive.myshopify.com/admin/collects.json"
  # GET request for all active collects
  @response = HTTParty.get(ellie_active_url)

  def self.print
    p @response.body
  end
end

CustomCollection.print
