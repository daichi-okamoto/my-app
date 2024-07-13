class Employee < ApplicationRecord
  default_scope { order(:position) }
  validates :name, presence: true
  validates :employee_type, inclusion: { in: %w[正社員 パート 派遣] }

  belongs_to :user
  has_many :shifts, dependent: :destroy
  has_many :shift_requests, dependent: :destroy

  validate :at_least_one_shift_selected

  private

  def at_least_one_shift_selected
    unless early_shift || day_shift || late_shift || night_shift
      errors.add(:base, "1つ以上シフトを選択してください")
    end
  end
end
