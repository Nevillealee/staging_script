require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'active_record'
require 'pp'
Dir['./models/*.rb'].each { |file| require file }

module YotposAPI
  # TODO(Neville Lee): change COPY [filename] before putting on AWS
  def self.import
    ActiveRecord::Base.connection.execute(
      "COPY yotpos
      FROM
      '/home/neville/Desktop/fam_brands/staging_app/csv/yotpo_march.csv'
      DELIMITER ','
      CSV HEADER;"
    )
    puts 'csv import successful!'
  end

  def self.convert_id
    stage = StagingProduct.all
    stagingIds = StagingProduct.find_by_sql(
      "SELECT
      staging_products.*,
      yotpos.*
      FROM
      yotpos
      INNER JOIN
      staging_products
      ON
      yotpos.product_title = staging_products.title;"
    )
    stagingIds.each do |matchedSp|
      yot = Yotpo.find_by(product_title: matchedSp['title'])
      yot['product_id'] = matchedSp['site_id']
      yot.save!
      puts "updated #{yot['product_title']}"
    end
  end

  def self.export
      CSV.open("/home/neville/Desktop/fam_brands/staging_app/csv/newCsv.csv", "wb") do |csv|
        csv << Yotpo.attribute_names
        Yotpo.all.each do |user|
          csv << user.attributes.values
        end
      end
    puts "csv export complete"
  end
end
