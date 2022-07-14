class Payment < ApplicationRecord
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :category, class_name: 'Category', foreign_key: 'category_id'

  validates :name, presence: true, length: { maximum: 50 }
  validates :amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000 }
  validates :user_id, presence: true
end
