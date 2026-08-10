class AddressesController < ApplicationController
  before_action :set_address, only: %i[ show update destroy ]

  # GET /addresses
  def index
    render json: paginate(Address.filter_by_name(params[:name]))
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

  private
    def set_address
      @address = Address.find(params.expect(:id))
    end

    def form
      AddressForm.new(**params.expect(address: [ :name, :kind, :legacy_id ]).to_h.symbolize_keys)
    end
end
