class Micropost < ApplicationRecord
  ModelDsl.default_scope -> { order(created_at: :desc) }
end
