class Relationship < ApplicationRecord
  enum :status, { active: 0 }
end
