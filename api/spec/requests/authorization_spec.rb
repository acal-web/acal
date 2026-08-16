require "rails_helper"

RSpec.describe "Authorization Matrix", type: :request do
  let(:admin) { create(:user, role: "administrador") }
  let(:financeiro) { create(:user, role: "financeiro_secretaria") }
  let(:tesoureiro) { create(:user, role: "tesoureiro") }
  let(:customer) { create(:customer) }
  let(:invoice) { create(:invoice) }

  describe "Role-based access to resources" do
    # Tesoureiro: read-only on cadastro, can pay invoices
    describe "tesoureiro access" do
      before { sign_in_as(tesoureiro) }

      context "reading resources" do
        it "can read customers" do
          get "/customers"
          expect(response).to have_http_status(:ok)
        end

        it "can read invoices" do
          get "/invoices"
          expect(response).to have_http_status(:ok)
        end
      end

      context "modifying resources" do
        it "cannot create customers" do
          post "/customers", params: {
            customer: {
              name: "Test",
              document: "12345678901"
            }
          }
          expect(response).to have_http_status(:forbidden)
        end

        it "can pay invoices" do
          patch "/invoices/#{invoice.id}/pay"
          expect(response).to have_http_status(:ok)
        end
      end

      context "admin functions" do
        it "cannot generate invoices" do
          post "/invoices/generate"
          expect(response).to have_http_status(:forbidden)
        end

        it "cannot access users" do
          get "/users"
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    # Financeiro/Secretaria: full CRUD on cadastro, generate invoices, can pay
    describe "financeiro_secretaria access" do
      before { sign_in_as(financeiro) }

      context "cadastro operations" do
        it "can create customers" do
          post "/customers", params: {
            customer: {
              name: "Test",
              document: "12345678901"
            }
          }
          expect(response).to have_http_status(:created)
        end

        it "can update customers" do
          patch "/customers/#{customer.id}", params: {
            customer: { name: "Updated" }
          }
          expect(response).to have_http_status(:ok)
        end
      end

      context "invoice operations" do
        it "can generate invoices" do
          post "/invoices/generate", params: {
            eligible_connections: []
          }
          # Response depends on actual data, but authorization should pass
          expect(response.status).not_to eq(403)
        end

        it "can pay invoices" do
          patch "/invoices/#{invoice.id}/pay"
          expect(response).to have_http_status(:ok)
        end
      end

      context "admin functions" do
        it "cannot access users" do
          get "/users"
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    # Administrador: full access
    describe "administrador access" do
      before { sign_in_as(admin) }

      it "can access users" do
        get "/users"
        expect(response).to have_http_status(:ok)
      end

      it "can perform all operations" do
        post "/customers", params: {
          customer: {
            name: "Test",
            document: "12345678901"
          }
        }
        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "Unauthenticated access" do
    it "returns 401 without a token" do
      get "/customers", skip_auth: true
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["code"]).to eq(1002)
    end

    it "returns 401 with an invalid token" do
      get "/customers", headers: { "Authorization" => "Bearer invalid_token" }, skip_auth: true
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Public actions" do
    it "allows login without authentication" do
      user = create(:user, username: "testuser", password: "password123")
      post "/session", params: {
        session: { username: "testuser", password: "password123" }
      }, skip_auth: true

      expect(response).to have_http_status(:created)
    end
  end
end
