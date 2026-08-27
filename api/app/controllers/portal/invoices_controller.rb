class Portal::InvoicesController < Portal::ApplicationController
  requires_permission "portal_invoices:read", only: %i[ index show pdf ]

  INVOICE_INCLUDES = { connection: { include: %i[ customer address category ] }, water_meter: {}, quality_analyses: {} }

  # GET /portal/invoices
  def index
    invoices = Invoice
      .filter_by_customer(current_customer.id)
      .unpaid
      .includes(connection: %i[customer address category], water_meter: {})
      .order(due_date: :asc)

    render json: paginate(invoices), include: INVOICE_INCLUDES
  end

  # GET /portal/invoices/:id
  def show
    render json: customer_invoice(params[:id]), include: INVOICE_INCLUDES
  end

  # GET /portal/invoices/:id/pdf
  def pdf
    invoice = customer_invoice(params[:id])

    send_data Invoices::BoletoPdfService.call(invoice), type: "application/pdf", disposition: "inline", filename: "fatura-#{invoice.id}.pdf"
  end

  private

  def customer_invoice(id)
    Invoice
      .joins(:connection)
      .where(connections: { customer_id: current_customer.id })
      .includes(connection: %i[customer address category], water_meter: {})
      .find(id)
  end
end
