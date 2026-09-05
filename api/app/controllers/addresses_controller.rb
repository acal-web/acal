class AddressesController < ApplicationController
  requires_permission "addresses:read", only: %i[ index show ]
  requires_permission "addresses:manage", only: %i[ create update destroy restore ]

  before_action :set_address, only: %i[ show update destroy ]
  before_action :set_address_unscoped, only: %i[ restore ]

  SORTABLE_COLUMNS = %w[ name ].freeze

  # GET /addresses
  def index
    addresses = active_scope.filter_by_name(params[:name])
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
    # "true" (default) → active only, "false" → soft deleted only, "all" → both.
    def active_scope
      case params[:active]
      when "false" then Address.deleted
      when "all" then Address.unscoped
      else Address
      end
    end

    def sort(collection)
      column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
      collection.order(column => params[:direction] == "desc" ? :desc : :asc)
    end

    def set_address
      @address = Address.find(params.expect(:id))
    end

    def set_address_unscoped
      @address = Address.unscoped.find(params.expect(:id))
    end

    def form
      AddressForm.new(**params.expect(address: [ :name, :legacy_id ]).to_h.symbolize_keys)
    end
end
