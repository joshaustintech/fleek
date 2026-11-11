class Micropost < ApplicationRecord
  self.validates :user_id, presence: true
end
