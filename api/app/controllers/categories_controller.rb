class CategoriesController < ApplicationController
  include SoftDeleteFilterable

  SORTABLE_COLUMNS = %w[ name group ].freeze

  requires_permission "categories:records:read", only: %i[ index show ]
  requires_permission "categories:records:create", only: :create
  requires_permission "categories:records:update", only: :update
  requires_permission "categories:records:delete", only: :destroy
  requires_permission "categories:records:restore", only: :restore

  before_action :set_category, only: %i[ show update destroy ]
  before_action :set_deleted_category, only: %i[ restore ]

  # GET /categories
  def index
    categories = active_scope(Category).filter_by_name(params[:name])
    render json: paginate(sort(categories))
  end

  # GET /categories/1
  def show
    render json: @category
  end

  # POST /categories
  def create
    @category = Category.create!(**form.to_h)
    render json: @category, status: :created, location: @category
  end

  # PATCH/PUT /categories/1
  def update
    @category.update!(**form.to_h)
    render json: @category
  end

  # DELETE /categories/1
  def destroy
    @category.soft_delete!
  end

  # PATCH /categories/1/restore
  def restore
    @category.restore!
    render json: @category
  end

  private
    # Without an explicit ORDER BY, Postgres is free to return rows in any
    # order — in practice heap order, which shifts whenever a row is updated.
    # Name ascending is the default so the listing stays stable.
    def sort(collection)
      column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
      collection.order(column => params[:direction] == "desc" ? :desc : :asc)
    end

    def set_category
      @category = Category.find(params.expect(:id))
    end

    def set_deleted_category
      @category = find_deleted!(Category)
    end

    def form
      params_hash = params.expect(
        category: [ :name, :description, :group, :has_water_meter, :water_price, :membership_price, :legacy_id ]
      ).to_h.symbolize_keys
      CategoryForm.new(**params_hash)
    end
end
