require "rails_helper"

RSpec.describe "Portal::Sessions", type: :request do
  describe "POST /portal/session (login)", :skip_auth do
    context "with valid CPF and customer_code" do
      it "returns a token and customer data" do
        customer = create(:customer)

        post "/portal/session", params: {
          session: { document: customer.document, customer_code: customer.customer_code }
        }

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body).to have_key("token")
        expect(body["token"]).to be_a(String)
        expect(body["customer"]["id"]).to eq(customer.id)
        expect(body["customer"]["name"]).to eq(customer.name)
      end

      it "resets failed_login_attempts on success" do
        customer = create(:customer, failed_login_attempts: 3)

        post "/portal/session", params: {
          session: { document: customer.document, customer_code: customer.customer_code }
        }

        expect(response).to have_http_status(:created)
        expect(customer.reload.failed_login_attempts).to eq(0)
      end
    end

    context "with a wrong customer_code" do
      it "returns 401 and does not leak whether the CPF exists" do
        customer = create(:customer)

        post "/portal/session", params: {
          session: { document: customer.document, customer_code: "000000" }
        }

        expect(response).to have_http_status(:unauthorized)
        expect(customer.reload.failed_login_attempts).to eq(1)
      end
    end

    context "with a nonexistent CPF" do
      it "returns 401 with the same generic message" do
        post "/portal/session", params: {
          session: { document: "00000000000", customer_code: "123456" }
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "after 5 failed attempts" do
      it "locks the account and rejects even the correct code" do
        customer = create(:customer)

        5.times do
          post "/portal/session", params: {
            session: { document: customer.document, customer_code: "000000" }
          }
        end
        expect(customer.reload).to be_locked

        post "/portal/session", params: {
          session: { document: customer.document, customer_code: customer.customer_code }
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with missing params" do
      it "returns 401" do
        post "/portal/session", params: { session: {} }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /portal/me" do
    it "returns the authenticated customer" do
      customer = create(:customer)
      sign_in_as_customer(customer)

      get "/portal/me"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(customer.id)
    end

    it "returns 401 without a token", :skip_auth do
      get "/portal/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a staff token", :skip_auth do
      user = create(:user)
      token = JwtToken.encode(user.id, group: user.role)

      get "/portal/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /portal/session (logout)" do
    it "returns 204" do
      customer = create(:customer)
      sign_in_as_customer(customer)

      delete "/portal/session"

      expect(response).to have_http_status(:no_content)
    end
  end
end
