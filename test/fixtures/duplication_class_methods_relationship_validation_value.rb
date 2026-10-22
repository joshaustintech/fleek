class Relationship < ApplicationRecord
  validates :follower_id, presence: false
end
