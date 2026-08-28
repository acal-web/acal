class Notification < ApplicationRecord
  belongs_to :address, -> { unscope(where: :deleted_at) }, optional: true
  belongs_to :category, -> { unscope(where: :deleted_at) }, optional: true
  belongs_to :sent_by, class_name: "User"

  validates :title, presence: true, length: { maximum: 65 }
  validates :body, presence: true, length: { maximum: 1000 }
end
