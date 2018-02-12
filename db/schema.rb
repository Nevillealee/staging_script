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

ActiveRecord::Schema.define(version: 20180209220619) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "options", force: :cascade do |t|
    t.string "site_id"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "values", array: true
    t.string "images", array: true
    t.string "image"
    t.integer "position"
    t.index ["product_id"], name: "index_options_on_product_id"
  end

  create_table "product_metafields", force: :cascade do |t|
    t.string "namespace"
    t.string "namespace_key"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_metafields_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "site_id"
    t.string "title", null: false
    t.string "body_html", default: ""
    t.string "vendor", null: false
    t.string "product_type", null: false
    t.string "handle"
    t.string "template_suffix"
    t.string "published_scope"
    t.jsonb "images"
    t.string "tags", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "variants", force: :cascade do |t|
    t.string "title"
    t.string "site_id"
    t.string "option1", null: false
    t.string "sku"
    t.string "price"
    t.string "barcode"
    t.boolean "compare_at_price"
    t.string "fulfillment_service"
    t.integer "grams"
    t.integer "image_id"
    t.string "inventory_management"
    t.string "inventory_policy"
    t.string "weight_unit"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
  end

  add_foreign_key "options", "products"
  add_foreign_key "product_metafields", "products"
  add_foreign_key "variants", "products"
end
