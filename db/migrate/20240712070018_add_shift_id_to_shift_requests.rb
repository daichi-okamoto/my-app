class AddShiftIdToShiftRequests < ActiveRecord::Migration[7.0]
  def change
    add_reference :shift_requests, :shift, foreign_key: true
  end
end
