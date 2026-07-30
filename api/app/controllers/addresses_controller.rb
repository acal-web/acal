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
    @address = Address.create!(kind:, name:)
    render json: @address, status: :created, location: @address
  end

  # PATCH/PUT /addresses/1
  def update
    if @address.update(address_params)
      render json: @address
    else
      render json: @address.errors, status: :unprocessable_content
    end
  end

  # DELETE /addresses/1
  def destroy
    @address.destroy!
  end

  private
    def set_address
      @address = Address.find(params.expect(:id))
    end

    def address_params
      params.expect(address: [ :name, :kind ])
    end

    def kind
      address_params[:kind]
    end

    def name
      address_params[:name]
    end
end
