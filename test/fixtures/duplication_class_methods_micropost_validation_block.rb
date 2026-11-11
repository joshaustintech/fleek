class Micropost < ApplicationRecord
  validates :user_id, presence: true do
  end
end
