class AddUserIdToShiftRequests < ActiveRecord::Migration[7.0]
  def change
    add_reference :shift_requests, :user, foreign_key: true
  end
end
