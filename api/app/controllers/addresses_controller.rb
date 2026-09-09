class AddressesController < ApplicationController
  include SoftDeleteFilterable

  requires_permission "addresses:records:read", only: %i[ index show ]
  requires_permission "addresses:records:create", only: :create
  requires_permission "addresses:records:update", only: :update
  requires_permission "addresses:records:delete", only: :destroy
  requires_permission "addresses:records:restore", only: :restore

  before_action :set_address, only: %i[ show update destroy ]
  before_action :set_deleted_address, only: %i[ restore ]

  SORTABLE_COLUMNS = %w[ name ].freeze

  # GET /addresses
  def index
    addresses = active_scope(Address).filter_by_name(params[:name])
    render json: paginate(sort(addresses))
  end

  # GET /addresses/1
  def show
    render json: @address
  end

  # POST /addresses
  def create
    @address = Address.create!(**form.to_h)
    render json: @address, status: :created, location: @address
  end

  # PATCH/PUT /addresses/1
  def update
    @address.update!(**form.to_h)
    render json: @address
  end

  # DELETE /addresses/1
  def destroy
    @address.soft_delete!
  end

  # PATCH /addresses/1/restore
  def restore
    @address.restore!
    render json: @address
  end

  private
    def sort(collection)
      column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
      collection.order(column => params[:direction] == "desc" ? :desc : :asc)
    end

    def set_address
      @address = Address.find(params.expect(:id))
    end

    def set_deleted_address
      @address = find_deleted!(Address)
    end

    def form
      AddressForm.new(**params.expect(address: [ :name, :legacy_id ]).to_h.symbolize_keys)
    end
end
