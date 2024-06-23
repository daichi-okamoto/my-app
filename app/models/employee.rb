class Employee < ApplicationRecord
  validates :name, presence: true
  validates :employee_type, inclusion: { in: %w[正社員 パート 派遣] }
  validates :available_shift, inclusion: { in: %w[早番 日勤 遅番 夜勤] }

  belongs_to :user
end
