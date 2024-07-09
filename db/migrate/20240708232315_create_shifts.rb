class CreateShifts < ActiveRecord::Migration[7.0]
  def change
    create_table :shifts do |t|
      t.date :date
      t.string :shift_type
      t.references :employee, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shifts, :date
    add_index :shifts, [:employee_id, :date], unique: true
  end
end
