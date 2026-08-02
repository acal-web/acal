class ConnectionsController < ApplicationController
  before_action :set_connection, only: %i[ show update destroy ]

  CONNECTION_INCLUDES = %i[ customer address category ]

  # GET /connections
  def index
    connections = Connection
      .filter_by_customer_name(params[:customer_name])
      .filter_by_customer_document(params[:customer_document])
      .filter_by_address_name(params[:address_name])
      .filter_by_category_id(params[:category_id])
      .filter_by_active(params[:active])
      .includes(:customer, :address, :category)

    render json: paginate(connections), include: CONNECTION_INCLUDES
  end

  # GET /connections/1
  def show
    render json: @connection, include: CONNECTION_INCLUDES
  end

  # POST /connections
  def create
    @connection = Connection.create!(customer_id:, address_id:, category_id:, active:, legacy_id:)
    render json: @connection, status: :created, location: @connection, include: CONNECTION_INCLUDES
  end

  # PATCH/PUT /connections/1
  def update
    @connection.update!(customer_id:, address_id:, category_id:, active:, legacy_id:)
    render json: @connection, include: CONNECTION_INCLUDES
  end

  # DELETE /connections/1
  def destroy
    @connection.soft_delete!
  end

  private
    def set_connection
      @connection = Connection.find(params.expect(:id))
    end

    def connection_params
      params.expect(connection: [ :customer_id, :address_id, :category_id, :active, :legacy_id ])
    end

    def customer_id
      connection_params[:customer_id]
    end

    def address_id
      connection_params[:address_id]
    end

    def category_id
      connection_params[:category_id]
    end

    def active
      connection_params.fetch(:active, true)
    end

    def legacy_id
      connection_params[:legacy_id]
    end
end
