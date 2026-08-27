class DashboardController < ApplicationController
  requires_permission "dashboard:read", only: :summary

  INVOICE_INCLUDES = { connection: { include: %i[customer address category] } }

  def summary
    data = Dashboard::SummaryService.call(
      year: params[:year],
      month: params[:month]
    )

    render json: {
      total_received: data[:total_received],
      total_received_today: data[:total_received_today],
      total_receivable: data[:total_receivable],
      invoices_received_count: data[:invoices_received_count],
      invoices_receivable_count: data[:invoices_receivable_count],
      invoices_paid_today_count: data[:invoices_paid_today_count],
      recent_invoices: data[:recent_invoices],
      members_by_category: data[:members_by_category]
    }, include: INVOICE_INCLUDES
  end
end
