class Micropost < ApplicationRecord
  validates :content, uniqueness: true, length: { maximum: 140 }
end
