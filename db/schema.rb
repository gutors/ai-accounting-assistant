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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_010002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accesses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "organization_id"], name: "index_accesses_on_account_id_and_organization_id", unique: true
    t.index ["account_id"], name: "index_accesses_on_account_id"
    t.index ["organization_id"], name: "index_accesses_on_organization_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "google_uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["google_uid"], name: "index_accounts_on_google_uid", unique: true, where: "(google_uid IS NOT NULL)"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "bank_id", null: false
    t.string "coordinates"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_id"], name: "index_bank_accounts_on_bank_id"
    t.index ["organization_id", "name"], name: "index_bank_accounts_on_organization_id_and_name", unique: true
    t.index ["organization_id", "slug"], name: "index_bank_accounts_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_bank_accounts_on_organization_id"
  end

  create_table "bank_statements", force: :cascade do |t|
    t.bigint "bank_account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "month_id", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_bank_statements_on_bank_account_id"
    t.index ["month_id", "bank_account_id"], name: "index_bank_statements_on_month_id_and_bank_account_id", unique: true
    t.index ["month_id"], name: "index_bank_statements_on_month_id"
  end

  create_table "banks", force: :cascade do |t|
    t.string "compe", null: false
    t.datetime "created_at", null: false
    t.string "ispb", null: false
    t.string "presentation_name", null: false
    t.datetime "updated_at", null: false
    t.index ["compe"], name: "index_banks_on_compe", unique: true
    t.index ["ispb"], name: "index_banks_on_ispb", unique: true
  end

  create_table "inflows", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.bigint "bank_statement_id", null: false
    t.datetime "created_at", null: false
    t.text "history", null: false
    t.date "occurred_on", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_statement_id", "occurred_on"], name: "index_inflows_on_bank_statement_id_and_occurred_on"
    t.index ["bank_statement_id"], name: "index_inflows_on_bank_statement_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "kind", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_invites_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_invites_on_organization_id"
  end

  create_table "months", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.string "year_month", null: false
    t.index ["organization_id", "year_month"], name: "index_months_on_organization_id_and_year_month", unique: true
    t.index ["organization_id"], name: "index_months_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "accountant_legal_name"
    t.string "accountant_pix_key"
    t.string "accountant_presentation_name"
    t.string "accountant_tax_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "package_archive_folder_id"
    t.string "package_archive_url"
    t.string "package_destination_email"
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.bigint "bank_statement_id", null: false
    t.datetime "created_at", null: false
    t.text "history", null: false
    t.date "occurred_on", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_statement_id", "occurred_on"], name: "index_payments_on_bank_statement_id_and_occurred_on"
    t.index ["bank_statement_id"], name: "index_payments_on_bank_statement_id"
  end

  add_foreign_key "accesses", "accounts"
  add_foreign_key "accesses", "organizations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_accounts", "banks"
  add_foreign_key "bank_accounts", "organizations"
  add_foreign_key "bank_statements", "bank_accounts"
  add_foreign_key "bank_statements", "months"
  add_foreign_key "inflows", "bank_statements"
  add_foreign_key "invites", "organizations"
  add_foreign_key "months", "organizations"
  add_foreign_key "payments", "bank_statements"
end
