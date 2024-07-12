class AddShiftIdToMemos < ActiveRecord::Migration[7.0]
  def change
    add_column :memos, :shift_id, :integer
  end
end
