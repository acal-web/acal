class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show update destroy ]
  before_action :set_category_unscoped, only: %i[ restore ]

  # GET /categories
  def index
    categories = active_scope.filter_by_name(params[:name])
    render json: paginate(categories)
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
    # "true" (default) → active only, "false" → soft deleted only, "all" → both.
    def active_scope
      case params[:active]
      when "false" then Category.deleted
      when "all" then Category.unscoped
      else Category
      end
    end

    def set_category
      @category = Category.find(params.expect(:id))
    end

    def set_category_unscoped
      @category = Category.unscoped.find(params.expect(:id))
    end

    def form
      params_hash = params.expect(
        category: [ :name, :description, :group, :has_water_meter, :water_price, :membership_price, :legacy_id ]
      ).to_h.symbolize_keys
      CategoryForm.new(**params_hash)
    end
end
