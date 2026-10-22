class Micropost < ApplicationRecord
  has_one_attached :photo do |attachable|
    attachable.variant :display, resize_to_limit: [500, 500]
  end
end
