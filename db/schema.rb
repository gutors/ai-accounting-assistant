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

ActiveRecord::Schema[8.1].define(version: 2026_09_16_010730) do
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

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "kind", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_invites_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_invites_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "accesses", "accounts"
  add_foreign_key "accesses", "organizations"
  add_foreign_key "invites", "organizations"
end
