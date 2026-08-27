class VersionController < ApplicationController
  allow_any_group only: :show

  # GET /version
  def show
    render json: { version: File.read(Rails.root.join("VERSION")).strip }
  end
end
