# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_02_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "kind"
    t.integer "legacy_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index "lower((kind)::text), lower((name)::text)", name: "index_addresses_on_kind_and_name_unique", unique: true, where: "(deleted_at IS NULL)"
    t.index ["name"], name: "index_addresses_on_name"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "group"
    t.boolean "has_water_meter", default: false, null: false
    t.integer "legacy_id"
    t.decimal "membership_price", precision: 10, scale: 2
    t.string "name"
    t.datetime "updated_at", null: false
    t.decimal "water_price", precision: 10, scale: 2
    t.index "lower((\"group\")::text), lower((name)::text)", name: "index_categories_on_group_and_name_unique", unique: true, where: "(deleted_at IS NULL)"
    t.index ["name"], name: "index_categories_on_name"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "document"
    t.integer "legacy_id"
    t.integer "membership_number"
    t.string "name"
    t.datetime "updated_at", null: false
    t.boolean "voter", default: false, null: false
    t.index ["document"], name: "index_customers_on_document", unique: true
    t.index ["name"], name: "index_customers_on_name"
  end
end
