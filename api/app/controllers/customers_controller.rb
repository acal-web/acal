class CustomersController < ApplicationController
  before_action :set_customer, only: %i[ show update destroy ]

  SORTABLE_COLUMNS = %w[ name document membership_number voter ].freeze

  # GET /customers
  def index
    customers = active_scope.filter_by_name(params[:name]).filter_by_document(params[:document])
    render json: paginate(sort(customers))
  end

  # GET /customers/1
  def show
    render json: @customer
  end

  # POST /customers
  def create
    @customer = Customer.create!(name:, document:, membership_number:, voter:, legacy_id:)
    render json: @customer, status: :created, location: @customer
  end

  # PATCH/PUT /customers/1
  def update
    @customer.update!(name:, document:, membership_number:, voter:, legacy_id:)
    render json: @customer
  end

  # DELETE /customers/1
  def destroy
    @customer.soft_delete!
  end

  private
    # "true" (default) → active only, "false" → soft deleted only, "all" → both.
    def active_scope
      case params[:active]
      when "false" then Customer.deleted
      when "all" then Customer.unscoped
      else Customer
      end
    end

    def sort(collection)
      return collection unless SORTABLE_COLUMNS.include?(params[:sort])

      collection.order(params[:sort] => params[:direction] == "desc" ? :desc : :asc)
    end

    def set_customer
      @customer = Customer.find(params.expect(:id))
    end

    def customer_params
      params.expect(customer: [ :name, :document, :membership_number, :voter, :legacy_id ])
    end

    def name
      customer_params[:name]
    end

    def document
      customer_params[:document]
    end

    def membership_number
      customer_params[:membership_number]
    end

    def voter
      customer_params.fetch(:voter, false)
    end

    def legacy_id
      customer_params[:legacy_id]
    end
end
