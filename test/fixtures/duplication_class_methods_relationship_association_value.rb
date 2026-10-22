class Relationship < ApplicationRecord
  belongs_to :follower, class_name: ENV.fetch("USER_CLASS")
end
