class Micropost < ApplicationRecord
  default_scope ->(record) { order(created_at: :desc) }
end
