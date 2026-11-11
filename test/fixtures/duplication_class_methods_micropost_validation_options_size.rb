class Micropost < ApplicationRecord
  validates :content, presence: true, length: { maximum: 140 }, allow_nil: true
end
