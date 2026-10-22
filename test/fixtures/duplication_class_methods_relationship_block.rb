class Relationship < ApplicationRecord
  belongs_to(:follower, class_name: "User") { |relation| relation }
end
