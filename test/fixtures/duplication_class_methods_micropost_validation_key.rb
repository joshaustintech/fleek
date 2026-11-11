class Micropost < ApplicationRecord
  validates :user_id, uniqueness: true
end
