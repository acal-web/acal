class ConnectionsController < ApplicationController
  before_action :set_connection, only: %i[ show update destroy ]

  CONNECTION_INCLUDES = %i[ customer address category ]

  # GET /connections
  def index
    connections = Connections::SearchService.call(
      customer_name: params[:customer_name],
      customer_document: params[:customer_document],
      address_name: params[:address_name],
      category_id: params[:category_id],
      active: params[:active]
    )

    render json: paginate(connections), include: CONNECTION_INCLUDES
  end

  # GET /connections/1
  def show
    render json: @connection, include: CONNECTION_INCLUDES
  end

  # POST /connections
  def create
    @connection = Connections::CreateService.call(
      customer_id:, address_id:, category_id:, active:, legacy_id:, membership_date:, exclusively_member:
    )
    render json: @connection, status: :created, location: @connection, include: CONNECTION_INCLUDES
  end

  # PATCH/PUT /connections/1
  def update
    @connection.update!(customer_id:, address_id:, category_id:, active:, legacy_id:, membership_date:, exclusively_member:)
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
      params.expect(connection: [ :customer_id, :address_id, :category_id, :active, :legacy_id, :membership_date, :exclusively_member ])
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

    def membership_date
      connection_params[:membership_date]
    end

    def exclusively_member
      connection_params.fetch(:exclusively_member, false)
    end
end
