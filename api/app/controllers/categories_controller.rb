class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show update destroy ]

  # GET /categories
  def index
    render json: paginate(Category.filter_by_name(params[:name]))
  end

  # GET /categories/1
  def show
    render json: @category
  end

  # POST /categories
  def create
    @category = Category.create!(name:, description:, group:, has_water_meter:, water_price:, membership_price:, legacy_id:)
    render json: @category, status: :created, location: @category
  end

  # PATCH/PUT /categories/1
  def update
    @category.update!(name:, description:, group:, has_water_meter:, water_price:, membership_price:, legacy_id:)
    render json: @category
  end

  # DELETE /categories/1
  def destroy
    @category.soft_delete!
  end

  private
    def set_category
      @category = Category.find(params.expect(:id))
    end

    def category_params
      params.expect(category: [ :name, :description, :group, :has_water_meter, :water_price, :membership_price, :legacy_id ])
    end

    def name
      category_params[:name]
    end

    def description
      category_params[:description]
    end

    def group
      category_params[:group]
    end

    def has_water_meter
      category_params.fetch(:has_water_meter, false)
    end

    def water_price
      category_params[:water_price]
    end

    def membership_price
      category_params[:membership_price]
    end

    def legacy_id
      category_params[:legacy_id]
    end
end
