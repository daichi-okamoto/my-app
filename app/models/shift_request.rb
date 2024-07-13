class ShiftRequest < ApplicationRecord
  belongs_to :employee
  belongs_to :user
  belongs_to :shift, optional: true

  validates :date, presence: true
  validates :shift_type, presence: true, inclusion: { in: %w[早番 日勤 遅番 夜勤 休み], allow_blank: true }
end
