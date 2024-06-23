class CreateEmployees < ActiveRecord::Migration[7.0]
  def change
    create_table :employees do |t|
      t.string :name
      t.string :employee_type
      t.references :user, null: false, foreign_key: true
      t.boolean :early_shift, default: false
      t.boolean :day_shift, default: false
      t.boolean :late_shift, default: false
      t.boolean :night_shift, default: false
      t.date :day_off_requests, array: true, default: []

      t.timestamps
    end
  end
end
