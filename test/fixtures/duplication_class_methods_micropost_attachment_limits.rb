class Micropost < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [600, 500]
  end
end
