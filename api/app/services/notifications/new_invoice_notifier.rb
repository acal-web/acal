module Notifications
  class NewInvoiceNotifier
    def self.call(connection:, invoice:)
      customer = connection.customer

      return unless customer

      Devices::SendPushService.call(
        owner: customer,
        title: "Nova fatura",
        body: "#{customer.name}, você possui uma nova fatura, na residência #{connection.full_location}, " \
              "no valor de #{Reports::PdfFactory.currency(invoice.amount)}"
      )
    end
  end
end
