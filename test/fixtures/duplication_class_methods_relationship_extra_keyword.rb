class Relationship < ApplicationRecord
  validates :follower_id, presence: true, length: { minimum: 1 }
end
