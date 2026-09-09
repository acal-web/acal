module Invoices
  # Groups unpaid, overdue invoices by connection — the current equivalent of
  # the legacy "idEnderecoPessoa" grouping used to drive the cobrança
  # (dunning letter) report.
  class OverdueConnectionsService
    # A connection whose oldest open invoice is overdue by more than this many
    # days is flagged as subject to having its service cut off.
    CUTOFF_DAYS = 59

    # The connections that have unpaid invoices overdue by `days`, as a
    # relation so callers can paginate it. Ordered by customer/address/number
    # so paging is stable.
    #
    # Soft-deleted connections are deliberately kept: an unpaid invoice still
    # has to be collected on a connection that has since been deactivated, and
    # that is what `Invoice#connection` already unscopes for.
    def self.connections_scope(days: 30, address_id: nil)
      Connection
        .unscope(where: :deleted_at)
        .where(id: overdue_invoices(days, address_id).select(:connection_id))
        .sort_by_field(nil)
    end

    # Total still open across every overdue invoice matching the filters —
    # the whole result set, not just one page of it.
    def self.total_amount(days: 30, address_id: nil)
      overdue_invoices(days, address_id).sum(Invoice::TOTAL_AMOUNT_SQL)
    end

    # Groups for the given filters. Pass `connections` (one page of
    # [connections_scope]) to restrict the groups to it and return them in that
    # same order; without it, every matching connection is grouped — which is
    # what the dunning PDF needs.
    def self.call(days: 30, address_id: nil, connections: nil)
      invoices = overdue_invoices(days, address_id)
      invoices = invoices.where(connection_id: connections.map(&:id)) if connections
      grouped = invoices.includes(connection: %i[ customer address category ]).order(:due_date).group_by(&:connection_id)

      ids = connections ? connections.map(&:id) : grouped.keys
      ids.filter_map { |id| serialize(grouped[id]) if grouped[id] }
    end

    def self.overdue_invoices(days, address_id)
      Invoice.overdue(days).filter_by_address(address_id)
    end
    private_class_method :overdue_invoices

    def self.serialize(connection_invoices)
      connection = connection_invoices.first.connection
      days_overdue = (Date.current - connection_invoices.map(&:due_date).min).to_i

      {
        connection_id: connection.id,
        connection_number: "#{connection.number}#{connection.letter}",
        customer: { id: connection.customer.id, name: connection.customer.name },
        address: { id: connection.address.id, name: connection.address.name },
        category: { id: connection.category.id, name: connection.category.name },
        invoices: connection_invoices.map { |invoice|
          { id: invoice.id, reference_date: invoice.reference_date, due_date: invoice.due_date, membership_value: invoice.membership_value, water_value: invoice.water_value }
        },
        total_amount: connection_invoices.sum(&:amount),
        days_overdue: days_overdue,
        subject_to_cutoff: days_overdue > CUTOFF_DAYS
      }
    end
    private_class_method :serialize
  end
end
