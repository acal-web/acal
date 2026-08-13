class CustomersController < ApplicationController
  before_action :set_customer, only: %i[ show update destroy ]
  before_action :set_deleted_customer, only: %i[ restore ]

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
    @customer = Customer.create!(**form.to_h)
    render json: @customer, status: :created, location: @customer
  end

  # PATCH/PUT /customers/1
  def update
    @customer.update!(**form.to_h)
    render json: @customer
  end

  # DELETE /customers/1
  def destroy
    @customer.soft_delete!
  end

  # PATCH /customers/1/restore
  def restore
    @customer.restore!
    render json: @customer
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

    def set_deleted_customer
      @customer = Customer.deleted.find(params.expect(:id))
    end

    def form
      params_hash = params.expect(customer: [ :name, :document, :membership_number, :voter, :legacy_id, tags: [] ]).to_h.symbolize_keys
      CustomerForm.new(**params_hash)
    end
end
