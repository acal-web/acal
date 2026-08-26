class VersionController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authorize_action!

  # GET /version
  def show
    render json: { version: File.read(Rails.root.join("VERSION")).strip }
  end
end
