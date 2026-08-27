module Devices
  class RegisterService
    def self.call(owner:, platform:, push_token: nil, device_model: nil, os_version: nil, app_version: nil)
      new(owner:, platform:, push_token:, device_model:, os_version:, app_version:).call
    end

    def initialize(owner:, platform:, push_token:, device_model:, os_version:, app_version:)
      @owner = owner
      @platform = platform
      @push_token = push_token
      @device_model = device_model
      @os_version = os_version
      @app_version = app_version
    end

    def call
      device = @push_token.present? ? Device.find_or_initialize_by(push_token: @push_token) : Device.new

      device.assign_attributes(
        owner: @owner,
        platform: @platform,
        push_token: @push_token,
        device_model: @device_model,
        os_version: @os_version,
        app_version: @app_version,
        last_seen_at: Time.current
      )
      device.save!
      device
    end
  end
end
