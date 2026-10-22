class Relationship < ApplicationRecord
  ModelDsl.belongs_to :follower, class_name: "User"
end
