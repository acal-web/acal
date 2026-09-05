module Rbac
  # Sentinel: qualquer grupo autenticado passa (equivalente a "authenticated, sem checagem de papel")
  ANY_GROUP = :any

  # Permissões de back-office compartilhadas por administrador e financeiro_secretaria.
  STAFF_PERMISSIONS = %w[
    customers:read customers:manage
    addresses:read addresses:manage
    categories:read categories:manage
    connections:read connections:manage
    quality_analyses:read quality_analyses:manage
    invoices:read invoices:generate invoices:pay
    dashboard:read
    notifications:read notifications:send
  ].freeze

  # Grupo de acesso → lista de permissões nomeadas ("recurso:ação") concedidas a esse grupo.
  GROUPS = {
    "administrador" => (%w[users:read users:manage test:reset] + STAFF_PERMISSIONS).freeze,
    "financeiro_secretaria" => STAFF_PERMISSIONS,
    "tesoureiro" => %w[
      customers:read addresses:read categories:read connections:read quality_analyses:read
      invoices:read invoices:pay
      dashboard:read
    ],
    "customer" => %w[
      portal_invoices:read
      portal_devices:manage
    ]
  }.freeze

  def self.can?(group, permission)
    return false if group.blank?
    return GROUPS.key?(group.to_s) if permission == ANY_GROUP

    GROUPS.fetch(group.to_s, []).include?(permission.to_s)
  end
end
