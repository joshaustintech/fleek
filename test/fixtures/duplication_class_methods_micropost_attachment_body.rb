class Micropost < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [500, 500]
    attachable.variant :thumb
  end
end
