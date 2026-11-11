class Article < ApplicationRecord
  belongs_to :author
  has_many :comments, dependent: :destroy
  validates :title, presence: true, length: { maximum: 140 }
  validates :body, presence: true, length: { maximum: 5000 }
  scope :published, -> { where(published: true).order(created_at: :desc) }
  scope :drafts, -> { where(published: false).order(updated_at: :desc) }

  def publish!(at: Time.current)
    update!(published: true, published_at: at)
    comments.each { |comment| comment.notify(:published, self) }
  end

  def retract!(at: Time.current)
    update!(retracted: true, retracted_at: at)
    comments.each { |comment| comment.notify(:retracted, self) }
  end
end
