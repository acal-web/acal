class UserForm
  attr_reader :username, :name, :password, :role

  def initialize(username: nil, name: nil, password: nil, role: nil)
    @username = username
    @name = name
    @password = password
    @role = role
  end

  def to_h
    { username:, name:, password:, role: }.compact
  end
end
