class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :event
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :purchased_at, presence: true
end