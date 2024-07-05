class AddPositionToEmployees < ActiveRecord::Migration[7.0]
  def change
    add_column :employees, :position, :integer
  end
end
