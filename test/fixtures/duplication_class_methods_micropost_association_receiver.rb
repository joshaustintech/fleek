class Micropost < ApplicationRecord
  ModelDsl.belongs_to :user
end
