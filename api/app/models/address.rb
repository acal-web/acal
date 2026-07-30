class Address < ApplicationRecord
  include SoftDeletable

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :kind, presence: true
  validate :kind_and_name_uniqueness

  private

  def kind_and_name_uniqueness
    return if kind.blank? || name.blank?

    duplicates = self.class.where("lower(kind) = ? AND lower(name) = ?", kind.downcase, name.downcase)
    duplicates = duplicates.where.not(id: id) if persisted?

    raise DuplicateResourceError, "Address already exists" if duplicates.exists?
  end
end
