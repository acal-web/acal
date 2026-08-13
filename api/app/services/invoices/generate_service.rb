module Invoices
  class GenerateService
    def self.call(connection_ids:, reference_date:, due_date:)
      connections = Connection.where(id: connection_ids).includes(:category)

      ActiveRecord::Base.transaction do
        connections.map do |connection|
          values = EligibleConnectionsService.value_breakdown(connection)
          Invoice.create!(
            connection_id: connection.id,
            reference_date: reference_date,
            due_date: due_date,
            membership_value: values[:membership_value],
            water_value: values[:water_value]
          )
        end
      end
    end
  end
end
