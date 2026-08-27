class Portal::DevicesController < Portal::ApplicationController
  requires_permission "portal_devices:manage", only: :create

  # POST /portal/devices
  def create
    device = Devices::RegisterService.call(owner: current_customer, **device_params)
    render json: { id: device.id }, status: :created
  end

  private

  def device_params
    params.expect(device: [ :platform, :push_token, :device_model, :os_version, :app_version ]).to_h.symbolize_keys
  end
end
