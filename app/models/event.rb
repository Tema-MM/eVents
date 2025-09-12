class Event < ApplicationRecord
  has_many :purchases, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true
  validates :date, presence: true
  validates :venue, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tickets_available, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Validate image attachment
  #validates :image, attached: true, content_type: { in: %w[image/jpg image/png image/jpeg], message: "must be a valid image format" }, size: { less_than: 5.megabytes, message: "should be less than 5MB" }
end