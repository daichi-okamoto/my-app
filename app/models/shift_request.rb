class ShiftRequest < ApplicationRecord
  belongs_to :employee

  validates :date, presence: true
  validates :shift_type, presence: true, inclusion: { in: %w[早番 日勤 遅番 夜勤 休み] }
end
