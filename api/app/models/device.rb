class Device < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :platform, presence: true, inclusion: { in: %w[ android ios ] }
end
