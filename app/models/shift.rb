class Shift < ApplicationRecord
  belongs_to :employee
  belongs_to :user

  validates :date, presence: true
  validates :shift_type, presence: true
end
