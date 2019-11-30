require 'httparty'
require 'dotenv/load'
require 'shopify_api'

Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }
module Rollover
  CURRENT_MONTH = Date.today.strftime("%B")
  CURRENT_YEAR = Date.today.strftime("%Y")
  NEXT_MONTH = Time.now.localtime.to_date >> 1
  # MMYY_collection (be be on all of last months 2,3,5, onetime, and auto renews) i.e. 1119_co...
  MY_TAG = "%#{Date.today.strftime('%m%y')}_collection%"
  RETURNING_TAG = "%#{NEXT_MONTH.strftime('%m%y')}R_collection%" # 1219R_collection
  RETURNING_PRODUCTS = StagingProduct.where("tags LIKE ?", RETURNING_TAG )
  ROLLOVER_PRODUCTS = StagingProduct.where("tags LIKE ?", MY_TAG ) - RETURNING_PRODUCTS

  COMING_SOON_TEMPLATE = "coming-soon"
  NOT_FOR_SALE_TEMPLATE = "not-for-sale"
  PAST_COLLECTION_TEMPLATE = "past-collection.bra"
  CURRENT_TEMPLATE = "current-collection-may2018"
  ONE_TIME_TEMPLATE = "one-time-purchase"
  EXCLUSIVE_TAG = "ellie-exclusive"

  EXCLUSIVES_COLLECTION_ID = "151042621579" # i.e. November 19 Exclusives colleciton ID
  PAST_COLLECTION_TITLE = "- The #{CURRENT_MONTH} Collection (#{CURRENT_YEAR})"
  PAST_COLLECTION_PRICE = "54.95"
  THREE_ITEM_PRICE = "44.95"

  def self.shopify_api_throttle
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:#{ENV['STAGING_API_PW']}"\
      "@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
      return if ShopifyAPI.credit_left > 3
      puts "limit reached sleeping 5"
    sleep 5
  end

  def self.isThreeItem?(_title)
    return /- 3 [iI]tem[sS]?/.match?(_title)
  end

  def self.isFiveItem?(_title)
    return /- 5 [iI]tem[sS]?/.match?(_title)
  end

  def self.isTwoItem?(_title)
    return /- 2 [iI]tem[sS]?/.match?(_title)
  end

  def self.isOneTime?(_title)
    return /- [Oo]ne [Tt]ime [Pp]urchase?/.match?(_title)
  end

  def self.isReturnCollection?(_title)
    _title.match?(/- [tT]he \w* Collection [(]\d{4}[)]/)
  end

  # pass in 'bring_back' for returning products, use 'add_to_past' if adding prod to past collections
  def self.changeTitle(_title, choice)
    if choice == "bring_back"
      return _title.gsub(/- [tT]he \w* Collection [(]\d{4}[)]/, "- 3 Items")
    elsif choice == "add_to_past"
      return _title.gsub(/- 3 [iI]tem[sS]?/, PAST_COLLECTION_TITLE)
    else
      return _title
    end
  end

  def self.changePriceTo(original_price, choice)
    if choice == "current"
      return THREE_ITEM_PRICE
    elsif choice == "past"
      return PAST_COLLECTION_PRICE
    else
      return original_price
    end
  end
  # valid choice: "not-for-sale", "comming-soon", "one-time-purchase", or "past"
  def self.changeTemplateTo(_orignal_template, choice)
    case choice
    when "not-for-sale"
      NOT_FOR_SALE_TEMPLATE
    when "coming-soon"
      COMING_SOON_TEMPLATE
    when "past-collection.bra" # only use midway through month when merchandising activates Exclusives
      PAST_COLLECTION_TEMPLATE
    when "one-time-purchase"
      ONE_TIME_TEMPLATE
    when "current-collection"
      CURRENT_TEMPLATE
    else
      _orignal_template
    end
  end

  def self.perform
    puts "ROLLOVER_PRODUCTS"
    ROLLOVER_PRODUCTS.each {|p| puts p.title}
    puts"--------------------------"
    ShopifyAPI::Base.site =
      "https://#{ENV['STAGING_API_KEY']}:"\
      "#{ENV['STAGING_API_PW']}@#{ENV['STAGING_SHOP']}.myshopify.com/admin"
    three_items = ROLLOVER_PRODUCTS.select { |prod| isThreeItem?(prod.title) }
    five_items = ROLLOVER_PRODUCTS.select { |prod| isFiveItem?(prod.title) }
    two_items = ROLLOVER_PRODUCTS.select { |prod| isTwoItem?(prod.title) }
    one_times = ROLLOVER_PRODUCTS.select { |prod| isOneTime?(prod.title) }

    # change old non returning 3 - Items into PAST COLLECTIONS w/ coming soon tag
    puts "change old non returning 3 - Items into PAST COLLECTIONS w/ coming soon tag"
    puts "three_items"
    three_items.each {|p| puts p.title}
    puts"--------------------------"
    three_items.each do |prod|
      begin
        shopify_api_throttle
        # update 3 Item product titles to past collection titles "- The {Month} Collection (YYYY)"
        shopify_prod = ShopifyAPI::Product.find(prod.id)
        shopify_prod.title = changeTitle(prod.title, "add_to_past")
        # update 3 item product prices to past collection prices 44.95 -> 54.95
        shopify_prod_variants = shopify_prod.variants
        shopify_prod_variants.each do |variant|
          variant.price = changePriceTo(variant.price, "past")
          variant.save!
          puts "new #{prod.title} price: #{variant.price}"
        end
        # update 3 Item product templates to product.coming-soon (past-collection.bra immediately 1219)
        shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "past-collection.bra")
        shopify_prod.save!
        puts "#{prod.title} -> #{shopify_prod.title}"
        puts "#{prod.title} template: #{prod.template_suffix} -> #{shopify_prod.template_suffix}"
      rescue StandardError => e
        puts prod.title
        puts "Error updating 3 Item product templates/prices/titles #{e}"
        next
      end
    end

    # update ellie exclusives collection with new products (MUST HAVES)
    puts "update ellie exclusives collection(#{EXCLUSIVES_COLLECTION_ID}) with new products (MUST HAVES)"
    CustomCollectionAPI.add_product_tags(EXCLUSIVES_COLLECTION_ID, EXCLUSIVE_TAG)

    # update Old one time  product templates to product.not-for-sale
    puts "update Old one time  product templates to product.not-for-sale"
    puts "one_times"
    one_times.each {|p| puts p.title}
    puts"--------------------------"
    one_times.each do |prod|
      begin
        shopify_api_throttle
        shopify_prod = ShopifyAPI::Product.find(prod.id)
        shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "not-for-sale")
        shopify_prod.save!
        puts "#{prod.title} template: #{prod.template_suffix} -> #{shopify_prod.template_suffix}"
      rescue StandardError => e
        puts prod.title
        puts "Error in old one-time product templates #{e}"
        next
      end
    end

    # update 5 Item and 2 Item product templates to product.not-for-sale
    puts "update 5 Item and 2 Item product templates to product.not-for-sale"
    puts "FIVE_ITEMS + TWO_ITEMS"
    (five_items + two_items).each {|p| puts p.title}
    puts"--------------------------"
    (five_items + two_items).each do |prod|
      begin
        shopify_api_throttle
        shopify_prod = ShopifyAPI::Product.find(prod.id)
        shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "not-for-sale")
        shopify_prod.save!
        puts "#{prod.title} template: #{prod.template_suffix} -> #{shopify_prod.template_suffix}"
      rescue StandardError => e
        puts prod.title
        puts "Error updating 2/5 Item product templates #{e}"
        next
      end
    end

    # set up returning products that werent on sale this month
    puts "set up returning products that werent on sale this month"
    puts "RETURNING_PRODUCTS"
    RETURNING_PRODUCTS.each {|p| puts p.title}
    puts"--------------------------"
    if RETURNING_PRODUCTS.any?
      returning_three_items = RETURNING_PRODUCTS.select { |prod| isReturnCollection?(prod.title) }
      returning_five_items = RETURNING_PRODUCTS.select { |prod| isFiveItem?(prod.title) }
      returning_two_items = RETURNING_PRODUCTS.select { |prod| isTwoItem?(prod.title) }
      returning_one_items = RETURNING_PRODUCTS.select { |prod| isOneTime?(prod.title) }
      # update returning (The #{Month} Collection (YYYY)) 3 Item product templates, prices, and titles
      returning_three_items.each do |prod|
        begin
          shopify_api_throttle
          shopify_prod = ShopifyAPI::Product.find(prod.id)
          shopify_prod.title = changeTitle(prod.title, "bring_back")
          shopify_prod_variants = shopify_prod.variants
          shopify_prod_variants.each do |variant|
            variant.price = changePriceTo(variant.price, "current")
            variant.save!
          end
          shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "current-collection")
          shopify_prod.save!
          puts "#{prod.title} -> #{shopify_prod.title}"
          puts "#{prod.title} template: #{prod.template_suffix} -> #{shopify_prod.template_suffix}"
        rescue StandardError => e
          puts prod.title
          puts "Error in returning 3 - Item product templates #{e}"
          next
        end
      end
      # update returning 5 Item and 2 Item product templates to product.current-collection-may2018
      (returning_five_items + returning_two_items).each do |prod|
        begin
          shopify_api_throttle
          shopify_prod = ShopifyAPI::Product.find(prod.id)
          shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "current-collection")
          shopify_prod.save!
          puts "#{prod.title} template: #{prod.template_suffix} -> #{shopify_prod.template_suffix}"
        rescue StandardError => e
          puts prod.title
          puts "Error in returning 2/3 Item product templates #{e}"
          next
        end
      end
      # update returning one-time product templates to product.one-time-purchase
      returning_one_items.each do |prod|
        begin
          shopify_api_throttle
          shopify_prod = ShopifyAPI::Product.find(prod.id)
          shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "one-time-purchase")
          shopify_prod.save!
          puts "#{prod.title} template: #{prod.template_suffix} -> #{shopify_prod.template_suffix}"
        rescue StandardError => e
          puts prod.title
          puts "Error in returning one-time product templates #{e}"
          next
        end
      end
    end
  end
end
