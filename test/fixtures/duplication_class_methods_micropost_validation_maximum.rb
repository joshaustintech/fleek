class Micropost < ApplicationRecord
  validates :content, presence: true, length: { maximum: 141 }
end
