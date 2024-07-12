class Shift < ApplicationRecord
  belongs_to :employee
  belongs_to :user
  has_many :memos, dependent: :destroy

  validates :date, presence: true
  validates :shift_type, presence: true
end
