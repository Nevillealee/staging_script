# Internal: Automate GET, POST, PUT requests to RechargeAPI
# for orders caching to local db
#
# Examples
#
#   $ rake order:save_actives
require 'httparty'
require 'dotenv/load'
require 'shopify_api'
require 'ruby-progressbar'

Dir['./modules/*.rb'].each {|file| require file }
Dir['./models/*.rb'].each {|file| require file }

module OrderAPI
  class Recent
    include ReChargeLimits
    def initialize
      recharge_regular = ENV['RECHARGE_ACTIVE_TOKEN']
      @sleep_recharge = ENV['RECHARGE_SLEEP_TIME']
      @my_header = {
        "X-Recharge-Access-Token" => recharge_regular
      }
      @uri = URI.parse(ENV['DATABASE_URL'])
    end

    def get_min_max
      my_yesterday = Date.today - 1
      my_yesterday_str = my_yesterday.strftime("%Y-%m-%d")
      my_four_months = Date.today >> 4
      my_four_months = my_four_months.end_of_month
      my_four_months_str = my_four_months.strftime("%Y-%m-%d")
      my_hash = Hash.new
      my_hash = {"min" => my_yesterday_str, "max" => my_four_months_str}
      return my_hash
    end
     # (1)pulls all queued orders scheduled_at > the day before yesterday
    def get_full_background_orders
      params = {"uri" => @uri, "headers" => @my_header}
      puts params.inspect
      uri = params['uri']
      my_header = params["headers"]
      min_max = get_min_max
      min = min_max['min']
      max = min_max['max']
      puts min_max.inspect

      orders_count = HTTParty.get("https://api.rechargeapps.com/orders/count?scheduled_at_min=\'#{min}\'&status=QUEUED", :headers => my_header)
      my_response = orders_count
      my_count = my_response['count'].to_i
      puts my_count
      puts my_response

      Order.delete_all
      ActiveRecord::Base.connection.reset_pk_sequence!('orders')

      myuri = @uri
      conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)

      my_insert = "insert into orders (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_order_number, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28)"
      conn.prepare('statement1', "#{my_insert}")

      start = Time.now
      page_size = 250
      num_pages = (my_count/page_size.to_f).ceil
      1.upto(num_pages) do |page|
        orders = HTTParty.get("https://api.rechargeapps.com/orders?scheduled_at_min=\'#{min}\'&status=queued&limit=250&page=#{page}", :headers => my_header)
        my_orders = orders.parsed_response['orders']
        recharge_limit = orders.response["x-recharge-limit"]
        puts "Here recharge_limit = #{recharge_limit}"
        puts "Here recharge_limit = #{recharge_limit}"
        my_orders.each do |order|
            puts order.inspect
            order_id = order['id']
            transaction_id = order['id']
            charge_status = order['charge_status']
            payment_processor = order['payment_processor']
            address_is_active = order['address_is_active'].to_i
            status = order['status']
            type = order['type']
            charge_id = order['charge_id']
            address_id = order['address_id']
            shopify_id = order['shopify_id']
            shopify_order_id = order['shopify_order_id']
            shopify_order_number = order['shopify_order_number']
            shopify_cart_token = order['shopify_cart_token']
            shipping_date = order['shipping_date']
            scheduled_at = order['scheduled_at']
            shipped_date = order['shipped_date']
            processed_at = order['processed_at']
            customer_id = order['customer_id']
            first_name = order['first_name']
            last_name = order['last_name']
            is_prepaid = order['is_prepaid'].to_i
            created_at = order['created_at']
            updated_at = order['updated_at']
            email = order['email']
            line_items = order['line_items'].to_json
            raw_line_items = order['line_items'][0]

            shopify_variant_id = raw_line_items['shopify_variant_id']
            title = raw_line_items['title']
            variant_title = raw_line_items['variant_title']
            subscription_id = raw_line_items['subscription_id']
            quantity = raw_line_items['quantity'].to_i
            shopify_product_id = raw_line_items['shopify_product_id']
            product_title = raw_line_items['product_title']

            total_price = order['total_price']
            shipping_address = order['shipping_address'].to_json
            billing_address = order['billing_address'].to_json
            #insert into orders
          conn.exec_prepared('statement1', [order_id, transaction_id, charge_status, payment_processor, address_is_active, status, type, charge_id, address_id, shopify_id, shopify_order_id, shopify_order_number, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address])
        end
        puts "Done with page #{page}"
        current = Time.now
        duration = (current - start).ceil
        puts "Been running #{duration} seconds"
        determine_limits(recharge_limit, 0.65)
      end
      puts "All done with FULL order download"
      conn.close
    end

    # (2)sets boolean has_sub_id value to false if Order doesnt have subscription_id in line_items
    def mark_falses
      my_orders = Order.all
      total = 0
      charge_ids=[]
      # adds charge ids to array for processesing
      my_orders.each do |order|
        if order.line_items[0]['subscription_id'] == nil
          puts "CHECK THIS ID: #{order.line_items}"
          total += 1
        else
          order.has_sub_id = false
          order.save!
          charge_ids << order.charge_id if !charge_ids.include?(order.charge_id)
        end
      end
      puts "total orders without subs: #{Order.all.count - total}/#{Order.all.count}"
      puts charge_ids.count
    end

    # (3)pulls subscription_id by from Charge API(recharge) by Order.charge_id and saves in
    # special Order field [subscription_id]
    def match_sub_ids
      bad_orders = Order.where(has_sub_id: false)
      bad_orders.each do |bad_order|
        # puts "charge_id: #{bad_order.charge_id}, order_id: #{bad_order.order_id}"
        response = HTTParty.get("https://api.rechargeapps.com/charges/#{bad_order.charge_id}", :headers => @my_header)
        my_charge = response.parsed_response['charge']
        puts "order line_item shopify_product_id: #{bad_order.line_items[0]["shopify_product_id"]}"
        if my_charge['line_items'].size > 1
          my_charge['line_items'].each do |charge_item|
            if (charge_item["shopify_product_id"].to_s == bad_order.line_items[0]["shopify_product_id"].to_s)
              puts "subscription_id"
              puts charge_item["subscription_id"]
              my_ord = Order.find_by_order_id(bad_order.order_id)
              puts "BEFORE: #{my_ord.inspect}"
              my_ord.subscription_id = charge_item["subscription_id"]
              my_ord.save!
              puts "AFTER: #{my_ord.inspect}"
            end
          end
          puts "--------------------\n"
        else
          puts "SINGLE LINE_ITEM CHARGE FOUND: #{my_charge['line_items']}"
          if (my_charge["line_items"][0]["shopify_product_id"].to_s == bad_order.line_items[0]["shopify_product_id"].to_s)
            puts "subscription_id"
            puts my_charge["line_items"][0]["subscription_id"]
            my_ord = Order.find_by_order_id(bad_order.order_id)
            puts "BEFORE: #{my_ord.inspect}"
            my_ord.subscription_id = my_charge["line_items"][0]["subscription_id"]
            my_ord.save!
            puts "AFTER: #{my_ord.inspect}"
          end
        end
      end
    end

    def reformat_oline_items(prop_array, subid)
      res = []
      prop_array.each do |l_item|
        new_line_item = {
          "properties" => l_item['properties'],
          "quantity" => l_item['quantity'].to_i,
          "sku" => l_item['sku'],
          "title" => l_item['title'],
          "variant_title" => l_item['variant_title'],
          "product_id" => l_item['shopify_product_id'].to_i,
          "variant_id" => l_item['shopify_variant_id'].to_i,
          "subscription_id" => subid.to_i,
        }
        res.push(new_line_item)
      end
      return res
    end

    def update_api
      recharge_token = ENV['RECHARGE_ACTIVE_TOKEN']
      @recharge_change_header = {
        'X-Recharge-Access-Token' => recharge_token,
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }
      orders_to_process = Order.where(has_sub_id: false)
      orders_to_process.each do |order|
        if order.subscription_id != nil
          my_hash = { "line_items" => reformat_oline_items(order.line_items, order.subscription_id) }
          body = my_hash.to_json
          puts "my hash: #{body.inspect}"
          @res = HTTParty.put("https://api.rechargeapps.com/orders/#{order.order_id}",:headers => @recharge_change_header, :body => body, :timeout => 80)
          puts @res.inspect
          order.has_sub_id = true if @res.code == 200
          order.save!
        end
      end
    end

  end
end
