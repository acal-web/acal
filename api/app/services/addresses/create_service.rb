module Addresses
  class CreateService
    def self.call(kind, name)
      Address.create!(kind:, name:)
    end
  end
end
