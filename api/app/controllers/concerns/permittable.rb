module Permittable
  extend ActiveSupport::Concern

  included do
    class_attribute :permission_requirements, instance_writer: false, default: {}
  end

  class_methods do
    # Declara a permissão nomeada ("recurso:ação") exigida para as ações listadas.
    def requires_permission(permission, only:)
      Array(only).each do |action|
        self.permission_requirements = permission_requirements.merge(action.to_sym => permission.to_s)
      end
    end

    # Qualquer grupo autenticado pode executar as ações listadas (sem checagem de permissão específica).
    def allow_any_group(only:)
      Array(only).each do |action|
        self.permission_requirements = permission_requirements.merge(action.to_sym => Rbac::ANY_GROUP)
      end
    end

    # Ação pública: não exige autenticação nem autorização (ex.: login).
    def skip_authentication(only:)
      Array(only).each do |action|
        self.permission_requirements = permission_requirements.merge(action.to_sym => :public)
      end
    end
  end

  def required_permission
    self.class.permission_requirements[action_name.to_sym]
  end
end
