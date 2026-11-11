class Micropost < ApplicationRecord
  validates :content, presence: true, length: { minimum: 140 }
end
