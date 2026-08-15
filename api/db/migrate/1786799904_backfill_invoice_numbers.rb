class BackfillInvoiceNumbers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE invoices
      SET number = numbered.invoice_number
      FROM (
        SELECT
          id,
          CONCAT(
            EXTRACT(YEAR FROM reference_date)::integer, '.',
            LPAD(EXTRACT(MONTH FROM reference_date)::integer::text, 2, '0'), '.',
            LPAD(ROW_NUMBER() OVER (
              PARTITION BY EXTRACT(YEAR FROM reference_date), EXTRACT(MONTH FROM reference_date)
              ORDER BY id
            )::text, 6, '0')
          ) AS invoice_number
        FROM invoices
        WHERE number IS NULL
      ) numbered
      WHERE invoices.id = numbered.id
    SQL
  end

  def down
    execute("UPDATE invoices SET number = NULL WHERE TRUE")
  end
end
