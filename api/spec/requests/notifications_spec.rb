require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:address) { create(:address) }
  let(:category) { create(:category) }

  describe "POST /notifications" do
    it "creates a notification, records the recipient count, and enqueues the broadcast for an administrador" do
      sign_in_as(create(:user))
      customer = create(:customer)
      create(:connection, customer: customer, address: address, category: category)

      expect {
        post "/notifications", params: { notification: { title: "Aviso", body: "Mensagem", address_id: address.id } }
      }.to have_enqueued_job(Notifications::BroadcastJob)

      expect(response).to have_http_status(:created)
      notification = Notification.find(response.parsed_body["id"])
      expect(notification.title).to eq("Aviso")
      expect(notification.recipient_count).to eq(1)
    end

    it "allows financeiro_secretaria" do
      sign_in_as(create(:user, :financeiro_secretaria))

      post "/notifications", params: { notification: { title: "Aviso", body: "Mensagem" } }

      expect(response).to have_http_status(:created)
    end

    it "forbids tesoureiro" do
      sign_in_as(create(:user, :tesoureiro))

      post "/notifications", params: { notification: { title: "Aviso", body: "Mensagem" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without a token", :skip_auth do
      post "/notifications", params: { notification: { title: "Aviso", body: "Mensagem" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /notifications/recipients_count" do
    it "returns the count of customers matching the filters" do
      sign_in_as(create(:user))
      customer = create(:customer)
      create(:connection, customer: customer, address: address, category: category)
      create(:connection, customer: create(:customer), address: create(:address), category: category)

      get "/notifications/recipients_count", params: { address_id: address.id }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["count"]).to eq(1)
    end
  end

  describe "GET /notifications" do
    it "lists past notifications" do
      sign_in_as(create(:user))
      create(:notification, title: "Antiga")

      get "/notifications"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"].map { |n| n["title"] }).to contain_exactly("Antiga")
    end
  end
end
