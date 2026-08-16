class UserSerializer
  include JSONAPI::Serializer

  attributes :username, :name, :role, :created_at, :updated_at
end
