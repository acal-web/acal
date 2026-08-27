class DevicesController < ApplicationController
  allow_any_group only: :create

  # POST /devices
  def create
    device = Devices::RegisterService.call(owner: current_user, **device_params)
    render json: { id: device.id }, status: :created
  end

  private

  def device_params
    params.expect(device: [ :platform, :push_token, :device_model, :os_version, :app_version ]).to_h.symbolize_keys
  end
end
