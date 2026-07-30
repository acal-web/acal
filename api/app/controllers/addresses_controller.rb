class AddressesController < ApplicationController
  before_action :set_address, only: %i[ show update destroy ]

  # GET /addresses
  def index
    render json: paginate(Address.all)
  end

  # GET /addresses/1
  def show
    render json: @address
  end

  # POST /addresses
  def create
    @address = Address.create!(kind:, name:, legacy_id:)
    render json: @address, status: :created, location: @address
  end

  # PATCH/PUT /addresses/1
  def update
    @address.update!(kind:, name:, legacy_id:)
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

    def address_params
      params.expect(address: [ :name, :kind, :legacy_id ])
    end

    def kind
      address_params[:kind]
    end

    def name
      address_params[:name]
    end

    def legacy_id
      address_params[:legacy_id]
    end
end
