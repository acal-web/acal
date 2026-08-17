class Permissions
  # Matriz de autorização: controller → ação → papéis permitidos
  # Uma entrada com :all significa "qualquer usuário autenticado"
  # Uma ação ausente da matriz defaults a administrador-only (segurança)
  MATRIX = {
    users: {
      index: %w[administrador],
      show: %w[administrador],
      create: %w[administrador],
      update: %w[administrador],
      destroy: %w[administrador],
      restore: %w[administrador]
    },
    customers: {
      index: %w[administrador financeiro_secretaria tesoureiro],
      show: %w[administrador financeiro_secretaria tesoureiro],
      create: %w[administrador financeiro_secretaria],
      update: %w[administrador financeiro_secretaria],
      destroy: %w[administrador financeiro_secretaria],
      restore: %w[administrador financeiro_secretaria]
    },
    addresses: {
      index: %w[administrador financeiro_secretaria tesoureiro],
      show: %w[administrador financeiro_secretaria tesoureiro],
      create: %w[administrador financeiro_secretaria],
      update: %w[administrador financeiro_secretaria],
      destroy: %w[administrador financeiro_secretaria],
      restore: %w[administrador financeiro_secretaria]
    },
    categories: {
      index: %w[administrador financeiro_secretaria tesoureiro],
      show: %w[administrador financeiro_secretaria tesoureiro],
      create: %w[administrador financeiro_secretaria],
      update: %w[administrador financeiro_secretaria],
      destroy: %w[administrador financeiro_secretaria],
      restore: %w[administrador financeiro_secretaria]
    },
    connections: {
      index: %w[administrador financeiro_secretaria tesoureiro],
      show: %w[administrador financeiro_secretaria tesoureiro],
      create: %w[administrador financeiro_secretaria],
      update: %w[administrador financeiro_secretaria],
      destroy: %w[administrador financeiro_secretaria]
    },
    quality_analyses: {
      index: %w[administrador financeiro_secretaria tesoureiro],
      show: %w[administrador financeiro_secretaria tesoureiro],
      create: %w[administrador financeiro_secretaria],
      update: %w[administrador financeiro_secretaria],
      destroy: %w[administrador financeiro_secretaria]
    },
    invoices: {
      index: %w[administrador financeiro_secretaria tesoureiro],
      show: %w[administrador financeiro_secretaria tesoureiro],
      eligible: %w[administrador financeiro_secretaria tesoureiro],
      generate: %w[administrador financeiro_secretaria],
      overdue: %w[administrador financeiro_secretaria tesoureiro],
      cobranca_pdf: %w[administrador financeiro_secretaria tesoureiro],
      print_filtered: %w[administrador financeiro_secretaria tesoureiro],
      pdf: %w[administrador financeiro_secretaria tesoureiro],
      pay: %w[administrador financeiro_secretaria tesoureiro]
    },
    dashboard: {
      summary: %w[administrador financeiro_secretaria tesoureiro]
    },
    me: {
      show: %w[administrador financeiro_secretaria tesoureiro]
    }
  }.freeze

  def self.allowed?(user, controller, action)
    return true if user.nil? && is_public_action?(controller, action)
    return false if user.nil?

    rules = MATRIX.fetch(controller.to_sym, {})
    roles = rules[action.to_sym] || %w[administrador]

    return true if roles == :all
    return true if roles == :public

    roles.include?(user.role)
  end

  def self.is_public_action?(controller, action)
    rules = MATRIX.fetch(controller.to_sym, {})
    roles = rules[action.to_sym]
    roles == :public
  end
end
