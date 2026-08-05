module Invoices
  class GenerateService
    def self.call(connection_ids:, reference_date:, due_date:)
      connections = Connection.where(id: connection_ids).includes(:category)

      ActiveRecord::Base.transaction do
        connections.map do |connection|
          Invoice.create!(
            connection_id: connection.id,
            reference_date: reference_date,
            due_date: due_date,
            amount: EligibleConnectionsService.amount_for(connection)
          )
        end
      end
    end
  end
end
