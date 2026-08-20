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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_005001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "legacy_id"
    t.citext "name"
    t.jsonb "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_addresses_on_name_unique", unique: true
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
    t.jsonb "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.decimal "water_price", precision: 10, scale: 2
    t.index "lower((\"group\")::text), lower((name)::text)", name: "index_categories_on_group_and_name_unique", unique: true
    t.index ["name"], name: "index_categories_on_name"
  end

  create_table "connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.uuid "address_id", null: false
    t.uuid "category_id", null: false
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.datetime "deleted_at"
    t.boolean "exclusively_member", default: false, null: false
    t.integer "legacy_id"
    t.string "letter"
    t.date "membership_date"
    t.integer "number", null: false
    t.jsonb "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.index "address_id, number, COALESCE(letter, ''::character varying)", name: "index_connections_on_address_id_number_letter_unique", unique: true, where: "(deleted_at IS NULL)"
    t.index "address_id, number, COALESCE(letter, ''::character varying), active", name: "index_connections_on_address_number_letter_active_unique", unique: true, where: "((active = true) AND (deleted_at IS NULL))"
    t.index ["address_id"], name: "index_connections_on_address_id"
    t.index ["category_id"], name: "index_connections_on_category_id"
    t.index ["customer_id"], name: "index_connections_on_customer_id"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "document"
    t.integer "legacy_id"
    t.integer "membership_number"
    t.string "name"
    t.jsonb "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.boolean "voter", default: false, null: false
    t.index "lower((document)::text) varchar_pattern_ops", name: "index_customers_document_lower"
    t.index "lower((name)::text) varchar_pattern_ops", name: "index_customers_name_lower"
    t.index ["document"], name: "index_customers_on_document", unique: true
    t.index ["membership_number"], name: "index_customers_on_membership_number"
    t.index ["name"], name: "index_customers_on_name"
    t.index ["voter"], name: "index_customers_on_voter"
  end

  create_table "invoices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "connection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.date "due_date", null: false
    t.datetime "last_updated_at"
    t.integer "legacy_id"
    t.decimal "membership_value", precision: 10, scale: 2, default: "0.0", null: false
    t.string "number"
    t.datetime "paid_at"
    t.date "reference_date", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.decimal "water_consumed_value"
    t.decimal "water_value", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["connection_id", "reference_date", "paid_at"], name: "index_invoices_on_connection_ref_paid", where: "(deleted_at IS NULL)"
    t.index ["connection_id", "reference_date"], name: "index_invoices_on_connection_id_and_reference_date_unique", unique: true, where: "(deleted_at IS NULL)"
    t.index ["connection_id"], name: "index_invoices_on_connection_id"
    t.index ["due_date", "paid_at"], name: "index_invoices_on_due_date_and_paid_at", where: "(deleted_at IS NULL)"
    t.index ["due_date"], name: "index_invoices_on_due_date", where: "(deleted_at IS NULL)"
    t.index ["legacy_id"], name: "index_invoices_on_legacy_id", unique: true
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["paid_at"], name: "index_invoices_on_paid_at", where: "(deleted_at IS NULL)"
    t.index ["reference_date", "paid_at"], name: "index_invoices_on_reference_date_and_paid_at", where: "(deleted_at IS NULL)"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "legacy_hidrometro", primary_key: "idhidrometro", id: :integer, default: nil, force: :cascade do |t|
    t.float "consumo"
    t.float "consumo_final"
    t.float "consumo_inicial"
    t.integer "idconta"
  end

  create_table "quality_analyses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "analyzed", null: false
    t.integer "compliant", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "legacy_id"
    t.string "param_name", null: false
    t.date "reference_date", null: false
    t.integer "required", null: false
    t.datetime "updated_at", null: false
    t.index ["legacy_id"], name: "index_quality_analyses_on_legacy_id", unique: true
    t.index ["reference_date", "param_name"], name: "index_quality_analyses_on_reference_date_and_param_name_unique", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.citext "username", null: false
    t.index ["username"], name: "index_users_on_username", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "water_meters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.decimal "final_reading", precision: 10, scale: 2, null: false
    t.decimal "initial_reading", precision: 10, scale: 2, null: false
    t.uuid "invoice_id", null: false
    t.integer "legacy_id"
    t.date "measured_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "measured_at"], name: "index_water_meters_on_invoice_id_and_measured_at", unique: true, where: "(deleted_at IS NULL)"
    t.index ["invoice_id"], name: "index_water_meters_on_invoice_id"
    t.index ["legacy_id"], name: "index_water_meters_on_legacy_id", unique: true
  end

  add_foreign_key "connections", "addresses"
  add_foreign_key "connections", "categories"
  add_foreign_key "connections", "customers"
  add_foreign_key "invoices", "connections"
  add_foreign_key "invoices", "users", on_delete: :nullify
  add_foreign_key "water_meters", "invoices"
end
