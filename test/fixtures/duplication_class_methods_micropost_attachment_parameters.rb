class Micropost < ApplicationRecord
  has_one_attached :image do |attachable, other|
    attachable.variant :display, resize_to_limit: [500, 500]
  end
end
