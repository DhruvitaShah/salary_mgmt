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

ActiveRecord::Schema[7.2].define(version: 2026_10_09_171253) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "country_code", limit: 2, null: false
    t.bigint "department_id", null: false
    t.bigint "job_title_id", null: false
    t.decimal "salary_amount", precision: 15, scale: 2, null: false
    t.string "currency", limit: 3, null: false
    t.decimal "salary_usd", precision: 15, scale: 2, null: false
    t.date "salary_effective_date", default: -> { "CURRENT_DATE" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_employees_on_lower_email", unique: true
    t.index ["country_code", "department_id"], name: "index_employees_on_country_code_and_department_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["employee_code"], name: "index_employees_on_code_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["job_title_id"], name: "index_employees_on_job_title_id"
    t.index ["name"], name: "index_employees_on_name"
    t.index ["name"], name: "index_employees_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["salary_usd"], name: "index_employees_on_salary_usd"
    t.check_constraint "salary_amount > 0::numeric", name: "employees_salary_positive"
  end

  create_table "job_titles", force: :cascade do |t|
    t.bigint "department_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id", "name"], name: "index_job_titles_on_department_id_and_name", unique: true
    t.index ["department_id"], name: "index_job_titles_on_department_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_until"
    t.datetime "last_sign_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
  add_foreign_key "job_titles", "departments"
end
