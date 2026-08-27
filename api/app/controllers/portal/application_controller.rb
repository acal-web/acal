class Portal::ApplicationController < ApplicationController
  private

  def current_customer
    @current_customer ||= current_user&.customer
  end
end
