class Micropost < ApplicationRecord
  validates :user_id, :content, presence: true
end
