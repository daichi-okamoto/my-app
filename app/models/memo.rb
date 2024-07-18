class Memo < ApplicationRecord
  belongs_to :user
  belongs_to :shift, optional: true
  
  validates :date, presence: true
  validates :content, presence: true, allow_blank: true # 空白の内容を許容
end
