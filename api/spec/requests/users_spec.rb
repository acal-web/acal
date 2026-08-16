require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:admin) { create(:user, role: "administrador") }

  describe "GET /users" do
    context "as admin" do
      before { sign_in_as(admin) }

      it "returns all users paginated" do
        create_list(:user, 13)

        get "/users"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["content"].size).to eq(10)
        expect(body).to have_key("hasNextPage")
        expect(body).to have_key("totalElements")
      end
    end

    context "as non-admin" do
      before { sign_in_as(create(:user, :tesoureiro)) }

      it "returns 403 Forbidden" do
        get "/users"

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["code"]).to eq(1003)
      end
    end
  end

  describe "POST /users (create)" do
    let(:user_params) do
      {
        user: {
          username: "newuser",
          name: "New User",
          password: "password123",
          role: "financeiro_secretaria"
        }
      }
    end

    context "as admin" do
      before { sign_in_as(admin) }

      it "creates a user and returns it" do
        post "/users", params: user_params

        expect(response).to have_http_status(:created)
        body = response.parsed_body["data"]
        expect(body["username"]).to eq("newuser")
        expect(body["name"]).to eq("New User")
        expect(body["role"]).to eq("financeiro_secretaria")
      end

      context "with invalid params" do
        it "returns unprocessable_content on validation errors" do
          post "/users", params: {
            user: {
              username: "",
              name: "No Username",
              password: "password123",
              role: "administrador"
            }
          }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "as non-admin" do
      before { sign_in_as(create(:user, :tesoureiro)) }

      it "returns 403 Forbidden" do
        post "/users", params: user_params

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /users/:id" do
    let(:target_user) { create(:user, name: "Old Name") }
    let(:update_params) do
      {
        user: {
          name: "Updated Name"
        }
      }
    end

    context "as admin" do
      before { sign_in_as(admin) }

      it "updates the user" do
        patch "/users/#{target_user.id}", params: update_params

        expect(response).to have_http_status(:ok)
        expect(target_user.reload.name).to eq("Updated Name")
      end
    end

    context "as non-admin" do
      before { sign_in_as(create(:user, :tesoureiro)) }

      it "returns 403 Forbidden" do
        patch "/users/#{target_user.id}", params: update_params

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /users/:id" do
    let(:target_user) { create(:user) }

    context "as admin deleting another user" do
      before { sign_in_as(admin) }

      it "soft deletes the user" do
        delete "/users/#{target_user.id}"

        expect(response).to have_http_status(:no_content)
        expect(target_user.reload.deleted_at).to be_present
      end
    end

    context "as admin deleting self" do
      before { sign_in_as(admin) }

      it "returns 403 Forbidden" do
        delete "/users/#{admin.id}"

        expect(response).to have_http_status(:forbidden)
        expect(admin.reload.deleted_at).to be_nil
      end
    end

    context "as non-admin" do
      before { sign_in_as(create(:user, :tesoureiro)) }

      it "returns 403 Forbidden" do
        delete "/users/#{target_user.id}"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /users/:id/restore" do
    let(:deleted_user) { create(:user, deleted_at: 1.day.ago) }

    context "as admin" do
      before { sign_in_as(admin) }

      it "restores a soft-deleted user" do
        patch "/users/#{deleted_user.id}/restore"

        expect(response).to have_http_status(:ok)
        expect(deleted_user.reload.deleted_at).to be_nil
      end
    end

    context "as non-admin" do
      before { sign_in_as(create(:user, :tesoureiro)) }

      it "returns 403 Forbidden" do
        patch "/users/#{deleted_user.id}/restore"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
