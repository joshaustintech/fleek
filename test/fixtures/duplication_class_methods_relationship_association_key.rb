class Relationship < ApplicationRecord
  belongs_to :other, class_name: "User"
end
