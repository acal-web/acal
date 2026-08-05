class InvoicesController < ApplicationController
  INVOICE_INCLUDES = { connection: { include: %i[ customer address category ] } }

  # GET /invoices
  def index
    invoices = Invoice.filter_by_period(params[:year], params[:month]).ordered.includes(connection: %i[ customer address category ])

    render json: paginate(invoices), include: INVOICE_INCLUDES
  end

  # GET /invoices/eligible
  def eligible
    connections = Invoices::EligibleConnectionsService.call(
      reference_date: params[:reference_date],
      has_water_meter: params[:has_water_meter],
      address_id: params[:address_id]
    )

    render json: connections
  end

  # POST /invoices/generate
  def generate
    invoices = Invoices::GenerateService.call(
      connection_ids: params.fetch(:connection_ids, []),
      reference_date: params[:reference_date],
      due_date: params[:due_date]
    )

    render json: invoices, status: :created
  end
end
