require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'active_record'
require 'pp'
Dir['./models/*.rb'].each { |file| require file }

module YotposAPI
  # TODO(Neville Lee): change COPY [filename] before putting on AWS
  def self.import_reviews(filename)
    time = Time.now.strftime("%b%d%Y")
    ActiveRecord::Base.connection.execute(
      "Truncate yotpos;"
    )
    ActiveRecord::Base.connection.execute(
      "COPY yotpos
      FROM
      '/home/neville/Desktop/fam_brands/staging_app/csv/#{filename}_#{time}.csv'
      DELIMITER ','
      CSV HEADER;"
    )
    puts 'csv import successful!'
  end

  #CONVERTS PRODUCT IDS IN YOTPO CSV (once imported) TO STAGING IDS
  def self.convert_id
    yot = Yotpo.all
    yot.each do |current_yot|
      sp = StagingProduct.find_by(title: current_yot['product_title'])
      if sp
        current_yot['product_id'] = sp['id']
        current_yot.save!
        puts "updated #{current_yot['product_title']} => #{current_yot['product_id']}"
      else
        puts "No match for #{current_yot['product_title']} on ellie staging.."
      end
    end
  end

  def self.export_reviews
    time = Time.now.strftime("%b%d%Y_%I%M")
      CSV.open("/home/neville/Desktop/fam_brands/staging_app/csv/yotpo_reviews_#{time}.csv", "wb") do |csv|
        csv << Yotpo.attribute_names
        Yotpo.all.each do |user|
          csv << user.attributes.values
        end
      end
    puts "csv export complete"
  end

  def self.export_products
    time = Time.now.strftime("%b%d%Y")
    product_url = "https://ellie.com/products/"
    CSV.open("/home/neville/Desktop/fam_brands/staging_app/csv/yotpo_products_#{time}.csv", "wb") do |csv|
      csv << [
        "Product ID",
        "Product Name",
        "Product Description",
        "Product URL",
        "Product Image URL",
        "Product Price",
        "Currency",
        "Spec UPC",
        "Spec SKU",
        "Spec Brand",
        "Spec MPN",
        "Spec ISBN",
        "Product Tags",
        "Blacklisted",
        "Product Group"
       ]
       Product.all.each do |product|
         product.images[0] ?  img_url = product.images[0]['src'] : img_url = ""
         csv << [
           "#{product.id}",
           "#{product.title}",
           "",
           "#{product_url}#{product.handle}",
           "#{img_url}",
           "",
           "",
           "",
           "",
           "",
           "",
           "",
           "",
           "",
           "",
         ]
       end
    end
  end

end
