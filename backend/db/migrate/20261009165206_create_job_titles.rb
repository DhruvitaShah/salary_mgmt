class CreateJobTitles < ActiveRecord::Migration[7.2]
  def change
    create_table :job_titles do |t|
      t.references :department, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :job_titles, %i[department_id name], unique: true
  end
end
