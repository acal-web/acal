module Rbac
  # Sentinel: qualquer grupo autenticado passa (equivalente a "authenticated, sem checagem de papel")
  ANY_GROUP = :any

  # Monta uma lista de códigos "módulo:feature:ação" para um conjunto de ações.
  def self.crud(mod, feature, actions)
    actions.map { |action| "#{mod}:#{feature}:#{action}" }
  end

  # Permissões de back-office compartilhadas por administrador e financeiro_secretaria.
  STAFF_PERMISSIONS = (
    crud("customers", "records", %i[read create update delete restore]) +
    crud("addresses", "records", %i[read create update delete restore]) +
    crud("categories", "records", %i[read create update delete restore]) +
    crud("connections", "records", %i[read create update delete]) +
    crud("quality_analyses", "records", %i[read create update delete]) +
    %w[invoices:records:read invoices:generation:execute invoices:payment:execute] +
    %w[dashboard:overview:read] +
    %w[notifications:records:read notifications:sending:execute]
  ).freeze

  # Grupo de acesso → lista de permissões nomeadas ("módulo:feature:ação") concedidas a esse grupo.
  GROUPS = {
    "administrador" => (
      crud("users", "records", %i[read create update delete restore]) +
      %w[test:data:reset elections:records:read documentation:records:read] +
      STAFF_PERMISSIONS
    ).freeze,
    "financeiro_secretaria" => STAFF_PERMISSIONS,
    "tesoureiro" => %w[
      customers:records:read addresses:records:read categories:records:read
      connections:records:read quality_analyses:records:read
      invoices:records:read invoices:payment:execute
      dashboard:overview:read
    ].freeze,
    "customer" => %w[
      portal:invoices:read
      portal:devices:create
    ].freeze
  }.freeze

  def self.can?(group, permission)
    return false if group.blank?
    return GROUPS.key?(group.to_s) if permission == ANY_GROUP

    GROUPS.fetch(group.to_s, []).include?(permission.to_s)
  end

  def self.permissions_for(group)
    GROUPS.fetch(group.to_s, [])
  end
end
