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

  # GET /invoices/:id/pdf
  def pdf
    invoice = Invoice.includes(connection: %i[ customer address category ]).find(params[:id])

    send_data Invoices::BoletoPdfService.call(invoice), type: "application/pdf", disposition: "inline", filename: "fatura-#{invoice.id}.pdf"
  end

  # PATCH /invoices/:id/pay
  def pay
    invoice = Invoice.find(params[:id])
    invoice.update!(paid_at: Time.current)

    render json: invoice, include: INVOICE_INCLUDES
  end

  # GET /invoices/overdue
  def overdue
    render json: Invoices::OverdueConnectionsService.call(days: overdue_days)
  end

  # GET /invoices/cobranca_pdf
  def cobranca_pdf
    groups = Invoices::OverdueConnectionsService.call(days: overdue_days)
    groups = groups.select { |group| group[:connection_id] == params[:connection_id] } if params[:connection_id].present?

    return head :no_content if groups.empty?

    send_data Invoices::CobrancaPdfService.call(groups), type: "application/pdf", disposition: "inline", filename: "cobranca.pdf"
  end

  private

  def overdue_days
    params[:days].presence&.to_i || 30
  end
end
