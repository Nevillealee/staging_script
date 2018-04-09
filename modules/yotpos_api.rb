require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'active_record'
require 'pp'
Dir['./models/*.rb'].each { |file| require file }

module YotposAPI
  # TODO(Neville Lee): change COPY [filename] before putting on AWS
  def self.import(filename)
    ActiveRecord::Base.connection.execute(
      "Truncate yotpos;"
    )
    ActiveRecord::Base.connection.execute(
      "COPY yotpos
      FROM
      '/home/neville/Desktop/fam_brands/staging_app/csv/#{filename}.csv'
      DELIMITER ','
      CSV HEADER;"
    )
    puts 'csv import successful!'
  end

  def self.convert_id
    yot = Yotpo.all
    yot.each do |current_yot|
      sp = StagingProduct.find_by(title: current_yot['product_title'])
      if sp
        current_yot['product_id'] = sp['site_id']
        current_yot.save!
        puts "updated #{current_yot['product_title']} => #{current_yot['product_id']}"
      else
        puts "No match for #{current_yot['product_title']} on ellie staging.."
      end
    end
  end

  def self.export
      CSV.open("/home/neville/Desktop/fam_brands/staging_app/csv/staging_yotpo.csv", "wb") do |csv|
        csv << Yotpo.attribute_names
        Yotpo.all.each do |user|
          csv << user.attributes.values
        end
      end
    puts "csv export complete"
  end
end
