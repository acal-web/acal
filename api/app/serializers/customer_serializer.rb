class CustomerSerializer
  include JSONAPI::Serializer

  attributes :name, :document, :membership_number, :voter, :legacy_id, :tags, :created_at, :updated_at
end
