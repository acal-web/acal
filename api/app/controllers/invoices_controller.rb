class InvoicesController < ApplicationController
  INVOICE_INCLUDES = { connection: { include: %i[ customer address category ] }, water_meter: {} }

  # GET /invoices
  def index
    invoices = Invoice
      .filter_by_period(params[:year], params[:month])
      .filter_by_customer(params[:customer_id])
      .filter_by_address(params[:address_id])
      .filter_by_status(params[:status])
      .includes(connection: %i[customer address category], water_meter: {})

    invoices = apply_sort(invoices, params[:sort_by], params[:sort_ascending] == "true")

    render json: paginate(invoices), include: INVOICE_INCLUDES
  end

  # GET /invoices/:id
  def show
    invoice = Invoice.includes(connection: %i[customer address category], water_meter: {}).find(params[:id])
    render json: invoice, include: INVOICE_INCLUDES
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
      due_date: params[:due_date],
      water_meters: params[:water_meters]
    )

    invoices = Invoice.where(id: invoices.map(&:id)).includes(connection: %i[customer address category], water_meter: {})

    render json: invoices, status: :created, include: INVOICE_INCLUDES
  end

  # GET /invoices/:id/pdf
  def pdf
    invoice = Invoice.includes(connection: %i[ customer address category ], water_meter: {}).find(params[:id])

    send_data Invoices::BoletoPdfService.call(invoice), type: "application/pdf", disposition: "inline", filename: "fatura-#{invoice.id}.pdf"
  end

  # PATCH /invoices/:id/pay
  def pay
    invoice = Invoice.includes(connection: %i[customer address category], water_meter: {}).find(params[:id])
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

  # GET /invoices/print_filtered
  def print_filtered
    invoices = Invoice
      .filter_by_period(params[:year], params[:month])
      .filter_by_customer(params[:customer_id])
      .filter_by_address(params[:address_id])
      .filter_by_status(params[:status])
      .ordered
      .includes(connection: %i[customer address category], water_meter: {})

    return head :no_content if invoices.empty?

    send_data Invoices::PrintFilteredPdfService.call(invoices), type: "application/pdf", disposition: "inline", filename: "faturas-filtradas.pdf"
  end

  private

  def overdue_days
    params[:days].presence&.to_i || 30
  end

  def apply_sort(invoices, sort_by, ascending = false)
    sort_column = case sort_by
    when "number" then "invoices.number"
    when "reference_date" then "invoices.reference_date"
    when "due_date" then "invoices.due_date"
    when "amount" then "(invoices.membership_value + invoices.water_value)"
    when "customer_name" then "customers.name"
    else "invoices.reference_date"
    end

    direction = ascending ? "ASC" : "DESC"

    if sort_by == "customer_name"
      invoices.joins(connection: :customer).order("#{sort_column} #{direction}")
    else
      invoices.order("#{sort_column} #{direction}")
    end
  end
end
