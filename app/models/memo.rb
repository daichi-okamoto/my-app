class Memo < ApplicationRecord
  belongs_to :user
  belongs_to :shift, optional: true
  
  validates :date, presence: true
  validates :content, presence: true
end
