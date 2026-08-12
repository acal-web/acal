module Dashboard
  class SummaryService
    def self.call(year: nil, month: nil)
      new(year: year, month: month).call
    end

    def initialize(year: nil, month: nil)
      today = Date.current
      @year = year&.to_i || today.year
      @month = month&.to_i || today.month
    end

    def call
      {
        total_received: total_received,
        total_receivable: total_receivable,
        invoices_received_count: invoices_received_count,
        invoices_receivable_count: invoices_receivable_count,
        recent_invoices: recent_invoices,
        members_by_category: members_by_category
      }
    end

    private

    def month_start
      Date.new(@year, @month, 1)
    end

    def month_end
      month_start.end_of_month
    end

    def total_received
      Invoice
        .where(paid_at: month_start..month_end)
        .sum(:amount)
        .to_f
    end

    def invoices_received_count
      Invoice
        .where(paid_at: month_start..month_end)
        .count
    end

    def total_receivable
      Invoice
        .filter_by_period(@year, @month)
        .unpaid
        .sum(:amount)
        .to_f
    end

    def invoices_receivable_count
      Invoice
        .filter_by_period(@year, @month)
        .unpaid
        .count
    end

    def recent_invoices
      Invoice
        .includes(connection: %i[customer address category])
        .order(updated_at: :desc)
        .limit(10)
    end

    def members_by_category
      counts = Connection
        .where(active: true)
        .joins(:category)
        .group("categories.group")
        .count

      Category::GROUPS.map do |group|
        { group: group, count: counts[group] || 0 }
      end
    end
  end
end
