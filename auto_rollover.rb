require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'activesupport'
Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }

CURRENT_MONTH = Date.today.strftime("%B")
CURRENT_YEAR = Date.today.strftime("%Y")
MY_TAG = "%#{Date.today.strftime('%m%y')}_collection%" # 1019_collection
ROLLOVER_PRODUCTS = Product.where("tags LIKE ?", MY_TAG )
COMING_SOON_TEMPLATE = "coming-soon"
NOT_FOR_SALE_TEMPLATE = "not-for-sale"
PAST_COLLECTION_TEMPLATE = "past-collection.bra"
ONE_TIME_TEMPLATE = "one-time-purchase"
EXCLUSIVE_TAG = "ellie-exclusive"
EXCLUSIVES_COLLECTION_ID = ""
PAST_COLLECTION_TITLE = "- The #{CURRENT_MONTH} Collection (#{CURRENT_YEAR})"
PAST_COLLECTION_PRICE = "54.95"
THREE_ITEM_PRICE = "44.95"

def isThreeItem?(_title)
  return /- 3 [iI]tem[sS]?/.match?(_title)
end

def isFiveItem?(_title)
  return /- 5 [iI]tem[sS]?/.match?(_title)
end

def isTwoItem?(_title)
  return /- 2 [iI]tem[sS]?/.match?(_title)
end

def isOneTime(_title)
  return /- [Oo]ne [Tt]ime [Pp]urchase/.match?(_title)
end

# pass in 'bring_back' for returning products, use 'add_to_past' if adding prod to past collections
def changeTitle(_title, choice)
  if choice == "bring_back"
    return _title.gsub(PAST_COLLECTION_TITLE, "- 3 Items")
  elsif choice == "add_to_past"
    return _title.gsub(/- 3 [iI]tem[sS]?/, PAST_COLLECTION_TITLE)
  else
    return _title
  end
end

def changePriceTo(original_price, choice)
  if choice == "current"
    return THREE_ITEM_PRICE
  elsif choice == "past"
    return PAST_COLLECTION_PRICE
  else
    return original_price
  end
end
# valid choice: "no_sale", "comming_soon", or "past"
def changeTemplateTo(_orignal_template, choice)
  if choice == "no_sale"
    return NOT_FOR_SALE_TEMPLATE
  elsif choice == "coming_soon"
    return COMING_SOON_TEMPLATE
  elsif choice == "past"
    return PAST_COLLECTION_TEMPLATE
  elsif choice == "one_time"
    return ONE_TIME_TEMPLATE
  else
    return _orignal_template
  end
end

def rollover
  ShopifyAPI::Base.site =
    "https://#{ENV['ACTIVE_API_KEY']}:"\
    "#{ENV['ACTIVE_API_PW']}@#{ENV['ACTIVE_SHOP']}.myshopify.com/admin"
  THREE_ITEMS = ROLLOVER_PRODUCTS.select { |prod| isThreeItem?(prod.title) }
  FIVE_ITEMS = ROLLOVER_PRODUCTS.select { |prod| isFiveItem?(prod.title) }
  TWO_ITEMS = ROLLOVER_PRODUCTS.select { |prod| isTwoItem?(prod.title) }
  ONE_TIMES = ROLLOVER_PRODUCTS.select { |prod| isOneTime?(prod.title) }

  THREE_ITEMS.each do |prod|
    # update 3 Item product titles to past collection titles "- The {Month} Collection (YYYY)"
    shopify_prod = ShopifyAPI::Product.find(prod.id)
    shopify_prod.title = changeTitle(prod.title, "add_to_past")
    # update 3 Item product templates to product.coming-soon
    shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "coming_soon")
    shopify_prod.save!
    # update 3 item product prices to past collection prices 44.95 -> 54.95
    shopify_prod_variants = shopify_prod.variants
    shopify_prod_variants.each do |variant|
      variant.price = changePriceTo(variant.price, "past")
      variant.save!
    end
  end
  
  # update ellie exclusives collection with new products
  CustomCollectionAPI.add_product_tags(EXCLUSIVES_COLLECTION_ID, EXCLUSIVE_TAG)

  # update 3 Item product templates to product.one-time-purchase
  ONE_TIMES.each do |prod|
    shopify_prod = ShopifyAPI::Product.find(prod.id)
    shopify_prod.template_suffix = changeTemplateTo(prod.template_suffix, "one_time")
    shopify_prod.save!
  end
end
