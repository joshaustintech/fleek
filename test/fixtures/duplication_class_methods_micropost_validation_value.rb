class Micropost < ApplicationRecord
  validates :user_id, presence: false
end
