# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190401201818) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title"
    t.bigint "blog_id"
    t.string "author"
    t.string "body_html"
    t.string "handle"
    t.jsonb "image"
    t.boolean "published"
    t.string "tags"
    t.string "template_suffix"
    t.bigint "user_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string "summary_html"
    t.datetime "published_at"
    t.jsonb "metafields"
    t.string "admin_graphql_api_id"
  end

  create_table "blogs", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title"
    t.string "handle"
    t.string "commentable"
    t.string "feedburner"
    t.string "feedburner_location"
    t.string "template_suffix"
    t.string "tags"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string "admin_graphql_api_id"
  end

  create_table "collects", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "collection_id"
    t.integer "position"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "featured"
  end

  create_table "custom_collections", id: :bigint, default: nil, force: :cascade do |t|
    t.string "handle"
    t.string "title"
    t.string "body_html"
    t.string "sort_order"
    t.string "template_suffix"
    t.string "published_scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "options", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "values", array: true
    t.string "images", array: true
    t.string "image"
    t.integer "position"
    t.index ["product_id"], name: "index_options_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_id"
    t.string "transaction_id"
    t.string "charge_status"
    t.string "payment_processor"
    t.integer "address_is_active"
    t.string "status"
    t.string "order_type"
    t.string "charge_id"
    t.string "address_id"
    t.string "shopify_id"
    t.string "shopify_order_id"
    t.string "shopify_order_number"
    t.string "shopify_cart_token"
    t.datetime "shipping_date"
    t.datetime "scheduled_at"
    t.datetime "shipped_date"
    t.datetime "processed_at"
    t.string "customer_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "is_prepaid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.jsonb "line_items"
    t.decimal "total_price", precision: 10, scale: 2
    t.jsonb "shipping_address"
    t.jsonb "billing_address"
    t.datetime "synced_at"
    t.boolean "has_sub_id", default: true
    t.bigint "subscription_id"
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["charge_id"], name: "index_orders_on_charge_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_id"], name: "index_orders_on_order_id"
    t.index ["shopify_id"], name: "index_orders_on_shopify_id"
    t.index ["shopify_order_id"], name: "index_orders_on_shopify_order_id"
    t.index ["shopify_order_number"], name: "index_orders_on_shopify_order_number"
    t.index ["transaction_id"], name: "index_orders_on_transaction_id"
  end

  create_table "pages", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title", null: false
    t.string "shop_id"
    t.string "handle"
    t.string "body_html", default: ""
    t.string "author"
    t.string "template_suffix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_metafields", id: :bigint, default: nil, force: :cascade do |t|
    t.string "namespace"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.bigint "owner_id"
    t.string "value_type"
  end

  create_table "products", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title", null: false
    t.string "body_html", default: ""
    t.string "vendor", null: false
    t.string "product_type", default: "", null: false
    t.string "handle"
    t.string "template_suffix"
    t.string "published_scope"
    t.jsonb "images"
    t.jsonb "image"
    t.string "tags", array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staging_blogs", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title"
    t.string "handle"
    t.string "commentable"
    t.string "feedburner"
    t.string "feedburner_location"
    t.string "template_suffix"
    t.string "tags"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string "admin_graphql_api_id"
  end

  create_table "staging_collects", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "new_cc_id"
    t.string "custom_collection_handle"
    t.bigint "old_cc_id"
    t.bigint "new_p_id"
    t.string "product_handle"
    t.bigint "old_p_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "featured"
  end

  create_table "staging_custom_collections", id: :bigint, default: nil, force: :cascade do |t|
    t.string "handle"
    t.string "title"
    t.string "body_html"
    t.string "sort_order"
    t.string "template_suffix"
    t.string "published_scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "staging_products", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title", null: false
    t.string "body_html"
    t.string "vendor", null: false
    t.string "product_type"
    t.string "handle"
    t.string "template_suffix"
    t.string "published_scope"
    t.jsonb "images"
    t.string "tags", array: true
    t.jsonb "image"
    t.jsonb "variants"
    t.jsonb "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "variants", id: :bigint, default: nil, force: :cascade do |t|
    t.string "title"
    t.string "option1"
    t.string "option2"
    t.string "sku", default: ""
    t.string "price"
    t.string "position"
    t.string "barcode", default: ""
    t.string "compare_at_price"
    t.string "fulfillment_service"
    t.bigint "grams"
    t.bigint "image_id"
    t.string "inventory_management"
    t.string "inventory_policy"
    t.string "inventory_quantity"
    t.string "weight_unit"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "inventory_item_id"
    t.index ["product_id"], name: "index_variants_on_product_id"
  end

  add_foreign_key "options", "products"
  add_foreign_key "variants", "products"
end
