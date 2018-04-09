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

ActiveRecord::Schema.define(version: 20180320145610) do

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
  end

  create_table "collects", force: :cascade do |t|
    t.string "collection_id"
    t.boolean "featured"
    t.string "site_id"
    t.integer "position"
    t.string "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "custom_collections", force: :cascade do |t|
    t.string "site_id"
    t.string "handle"
    t.string "title"
    t.string "body_html"
    t.string "sort_order"
    t.string "template_suffix"
    t.string "published_scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "options", force: :cascade do |t|
    t.string "site_id"
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

  create_table "pages", force: :cascade do |t|
    t.string "site_id"
    t.string "title", null: false
    t.string "shop_id"
    t.string "handle"
    t.string "body_html", default: ""
    t.string "author"
    t.string "template_suffix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_metafields", force: :cascade do |t|
    t.string "namespace"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.string "owner_id"
    t.string "value_type"
  end

  create_table "products", force: :cascade do |t|
    t.string "site_id"
    t.string "title", null: false
    t.string "body_html", default: ""
    t.string "vendor", null: false
    t.string "product_type", default: "", null: false
    t.string "handle"
    t.string "template_suffix"
    t.string "published_scope"
    t.jsonb "images"
    t.string "tags", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "image"
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
  end

  create_table "staging_collects", force: :cascade do |t|
    t.string "new_cc_id"
    t.string "custom_collection_handle"
    t.string "old_cc_id"
    t.string "new_p_id"
    t.string "product_handle"
    t.string "old_p_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "staging_custom_collections", force: :cascade do |t|
    t.string "site_id"
    t.string "handle"
    t.string "title"
    t.string "body_html"
    t.string "sort_order"
    t.string "template_suffix"
    t.string "published_scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "staging_products", force: :cascade do |t|
    t.string "site_id"
    t.string "title", null: false
    t.string "body_html"
    t.string "vendor", null: false
    t.string "product_type"
    t.string "handle"
    t.string "template_suffix"
    t.string "published_scope"
    t.jsonb "images"
    t.string "tags", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "image"
  end

  create_table "variants", force: :cascade do |t|
    t.string "title"
    t.string "site_id"
    t.string "option1", null: false
    t.string "sku", default: ""
    t.string "price"
    t.string "barcode", default: ""
    t.boolean "compare_at_price"
    t.string "fulfillment_service"
    t.bigint "grams"
    t.bigint "image_id"
    t.string "inventory_management"
    t.string "inventory_policy"
    t.string "weight_unit"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
  end

  create_table "yotpos", id: false, force: :cascade do |t|
    t.bigint "id", null: false
    t.string "user_type"
    t.string "appkey"
    t.boolean "published"
    t.string "review_title"
    t.string "review_content"
    t.integer "review_score"
    t.datetime "date"
    t.string "product_id"
    t.string "product_url"
    t.string "product_title"
    t.string "product_description"
    t.string "product_image_url"
    t.string "display_name"
    t.string "email"
    t.string "comment_content"
    t.string "comment_public"
    t.datetime "comment_created_at"
    t.string "published_image_url"
    t.string "unpublished_image_url"
    t.string "cf_Default_form_Fit"
  end

  add_foreign_key "options", "products"
  add_foreign_key "variants", "products"
end
