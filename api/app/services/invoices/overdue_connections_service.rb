module Invoices
  # Groups unpaid, overdue invoices by connection — the current equivalent of
  # the legacy "idEnderecoPessoa" grouping used to drive the cobrança
  # (dunning letter) report.
  class OverdueConnectionsService
    def self.call(days: 30)
      invoices = Invoice.overdue(days)
        .includes(connection: %i[ customer address category ])
        .order(:due_date)

      invoices.group_by(&:connection).map do |connection, connection_invoices|
        {
          connection_id: connection.id,
          connection_number: "#{connection.number}#{connection.letter}",
          customer: { id: connection.customer.id, name: connection.customer.name },
          address: { id: connection.address.id, name: connection.address.name },
          category: { id: connection.category.id, name: connection.category.name },
          invoices: connection_invoices.map { |invoice|
            { id: invoice.id, reference_date: invoice.reference_date, due_date: invoice.due_date, amount: invoice.amount }
          },
          total_amount: connection_invoices.sum(&:amount)
        }
      end
    end
  end
end
