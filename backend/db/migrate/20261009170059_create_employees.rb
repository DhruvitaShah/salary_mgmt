class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    enable_extension "pg_trgm"

    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :country_code, null: false, limit: 2
      t.references :department, null: false, foreign_key: true
      t.references :job_title, null: false, foreign_key: true

      # Current salary: annual gross base for a full-time employee, in local currency.
      t.decimal :salary_amount, precision: 15, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      # USD equivalent at the fixed rates in config/exchange_rates.yml. Stored so that
      # cross-country sorting and aggregation are plain indexed SQL.
      t.decimal :salary_usd, precision: 15, scale: 2, null: false
      t.date :salary_effective_date, null: false, default: -> { "CURRENT_DATE" }

      t.timestamps
    end

    add_check_constraint :employees, "salary_amount > 0", name: "employees_salary_positive"

    add_index :employees, :employee_code, unique: true
    add_index :employees, "lower(email)", unique: true, name: "index_employees_on_lower_email"
    add_index :employees, :name
    # department_id and job_title_id already indexed by t.references
    add_index :employees, %i[country_code department_id]
    add_index :employees, :salary_usd

    # Fast substring search (ILIKE '%term%') on the three searchable columns.
    add_index :employees, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_employees_on_name_trgm"
    add_index :employees, :email, using: :gin, opclass: :gin_trgm_ops, name: "index_employees_on_email_trgm"
    add_index :employees, :employee_code, using: :gin, opclass: :gin_trgm_ops, name: "index_employees_on_code_trgm"
  end
end
