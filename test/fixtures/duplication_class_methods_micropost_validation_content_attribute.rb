class Micropost < ApplicationRecord
  validates :title, presence: true, length: { maximum: 140 }
end
