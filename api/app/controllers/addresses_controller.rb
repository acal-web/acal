class AddressesController < ApplicationController
  before_action :set_address, only: %i[ show update destroy ]
  before_action :set_address_unscoped, only: %i[ restore ]

  SORTABLE_COLUMNS = %w[ name ].freeze

  # GET /addresses
  def index
    addresses = active_scope.filter_by_name(params[:name]).order(:name)
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
      return collection unless SORTABLE_COLUMNS.include?(params[:sort])

      collection.order(params[:sort] => params[:direction] == "desc" ? :desc : :asc)
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
