class Micropost < ApplicationRecord
  belongs_to(:user) { |relation| relation }
end
