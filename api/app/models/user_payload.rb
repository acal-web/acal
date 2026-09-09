module UserPayload
  def self.build(user)
    {
      id: user.id,
      username: user.username,
      name: user.name,
      role: user.role,
      created_at: user.created_at,
      updated_at: user.updated_at,
      permissions: Rbac.permissions_for(user.role)
    }
  end
end
