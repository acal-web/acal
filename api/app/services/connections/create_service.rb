module Connections
  class CreateService
    DEFAULTS = { letter: nil, active: true, legacy_id: nil, membership_date: nil, exclusively_member: false, tags: [] }.freeze

    def self.call(attributes)
      Connection.create!(DEFAULTS.merge(attributes))
    end
  end
end
