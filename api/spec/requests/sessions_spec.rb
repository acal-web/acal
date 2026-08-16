require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "POST /session (login)", :skip_auth do
    context "with valid credentials" do
      it "returns a token and user data" do
        User.create!(username: "testuser", name: "Test User", password: "password123", role: :administrador)

        post "/session", params: {
          session: {
            username: "testuser",
            password: "password123"
          }
        }

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body).to have_key("token")
        expect(body["token"]).to be_a(String)
        expect(body).to have_key("user")
        expect(body["user"]["username"]).to eq("testuser")
        expect(body["user"]["role"]).to eq("administrador")
      end
    end

    context "with invalid password" do
      it "returns 401 InvalidCredentialsError" do
        User.create!(username: "testuser2", name: "Test User 2", password: "password123", role: :administrador)

        post "/session", params: {
          session: {
            username: "testuser2",
            password: "wrongpassword"
          }
        }

        expect(response).to have_http_status(:unauthorized)
        body = response.parsed_body
        expect(body["code"]).to eq(1004)
      end
    end

    context "with nonexistent username" do
      it "returns 401 InvalidCredentialsError" do
        post "/session", params: {
          session: {
            username: "nonexistent",
            password: "password123"
          }
        }

        expect(response).to have_http_status(:unauthorized)
        body = response.parsed_body
        expect(body["code"]).to eq(1004)
      end
    end

    context "with missing params" do
      it "returns 401 for empty credentials" do
        post "/session", params: { session: {} }

        expect(response).to have_http_status(:unauthorized)
        body = response.parsed_body
        expect(body["code"]).to eq(1004)
      end
    end
  end

  describe "DELETE /session (logout)" do
    context "when authenticated" do
      it "destroys the session and returns 204" do
        delete "/session", headers: auth_headers

        expect(response).to have_http_status(:no_content)
        expect(Session.find_by(token_digest: Session.digest(auth_headers["Authorization"].delete_prefix("Bearer ")))).to be_nil
      end
    end

    context "when not authenticated", :skip_auth do
      it "returns 401" do
        delete "/session"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
