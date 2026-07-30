module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope { where(deleted_at: nil) }

    scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  end
end
