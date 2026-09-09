module SoftDeleteFilterable
  extend ActiveSupport::Concern

  # "true" (default) → active only, "false" → soft deleted only, "all" → both.
  def active_scope(model)
    case params[:active]
    when "false" then model.deleted
    when "all" then model.unscoped
    else model
    end
  end

  # For actions that only make sense on an already soft-deleted record (e.g. restore).
  def find_deleted!(model)
    model.deleted.find(params.expect(:id))
  end
end
