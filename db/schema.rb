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

ActiveRecord::Schema[7.0].define(version: 2024_07_21_212455) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "contacts", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "employee_type"
    t.bigint "user_id", null: false
    t.boolean "early_shift", default: false
    t.boolean "day_shift", default: false
    t.boolean "late_shift", default: false
    t.boolean "night_shift", default: false
    t.date "day_off_requests", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "memos", force: :cascade do |t|
    t.date "date"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "shift_id"
    t.index ["user_id"], name: "index_memos_on_user_id"
  end

  create_table "shift_requests", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.date "date"
    t.string "shift_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "shift_id"
    t.index ["employee_id"], name: "index_shift_requests_on_employee_id"
    t.index ["shift_id"], name: "index_shift_requests_on_shift_id"
    t.index ["user_id"], name: "index_shift_requests_on_user_id"
  end

  create_table "shifts", force: :cascade do |t|
    t.date "date"
    t.string "shift_type"
    t.bigint "employee_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_shifts_on_date"
    t.index ["employee_id", "date"], name: "index_shifts_on_employee_id_and_date", unique: true
    t.index ["employee_id"], name: "index_shifts_on_employee_id"
    t.index ["user_id"], name: "index_shifts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "employees", "users"
  add_foreign_key "memos", "users"
  add_foreign_key "shift_requests", "employees"
  add_foreign_key "shift_requests", "shifts"
  add_foreign_key "shift_requests", "users"
  add_foreign_key "shifts", "employees"
  add_foreign_key "shifts", "users"
end
