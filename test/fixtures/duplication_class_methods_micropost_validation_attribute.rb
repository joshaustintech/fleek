class Micropost < ApplicationRecord
  validates :title, presence: true
end
