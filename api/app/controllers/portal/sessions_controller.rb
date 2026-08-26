class Portal::SessionsController < Portal::ApplicationController
  skip_before_action :authenticate_customer!, only: :create

  INVALID_CREDENTIALS_MESSAGE = "CPF ou código do cliente inválidos"

  # POST /portal/session
  def create
    document = params.dig(:session, :document).to_s.gsub(/\D/, "")
    customer_code = params.dig(:session, :customer_code).to_s.strip

    raise InvalidCredentialsError.new(INVALID_CREDENTIALS_MESSAGE) if document.blank? || customer_code.blank?

    customer = Customer.find_by(document: document)
    raise InvalidCredentialsError.new(INVALID_CREDENTIALS_MESSAGE) if customer.nil? || customer.locked?

    if customer.customer_code == customer_code
      customer.reset_login_attempts!
      token = JwtToken.encode(customer.id, key: :customer_id)
      render json: { token: token, customer: customer_json(customer) }, status: :created
    else
      customer.register_failed_login!
      raise InvalidCredentialsError.new(INVALID_CREDENTIALS_MESSAGE)
    end
  end

  # GET /portal/me
  def me
    render json: customer_json(current_customer)
  end

  # DELETE /portal/session
  def destroy
    # JWT is stateless, so there's nothing to destroy on the server
    # Client just discards the token
    head :no_content
  end

  private

  def customer_json(customer)
    {
      id: customer.id,
      name: customer.name,
      document: customer.document
    }
  end
end
