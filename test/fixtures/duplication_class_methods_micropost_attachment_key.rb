class Micropost < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :display, resize: [500, 500]
  end
end
