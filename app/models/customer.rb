# frozen_string_litera: true

class Customer < ApplicationRecord
  belongs_to :organization

  has_many :subscriptions

  validates :customer_id, presence: true
end
