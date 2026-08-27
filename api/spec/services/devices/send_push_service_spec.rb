require "rails_helper"

RSpec.describe Devices::SendPushService do
  let(:customer) { create(:customer) }

  context "without Firebase credentials configured" do
    it "does not attempt to reach FCM" do
      create(:device, owner: customer, push_token: "token-123")

      expect(Net::HTTP).not_to receive(:post_form)

      expect { described_class.call(owner: customer, title: "Nova fatura", body: "oi") }.not_to raise_error
    end
  end

  context "with Firebase credentials configured" do
    let(:private_key) { OpenSSL::PKey::RSA.new(2048).to_pem }

    before do
      allow(Rails.application.credentials).to receive(:firebase).and_return(
        project_id: "test-project",
        client_email: "svc@test-project.iam.gserviceaccount.com",
        private_key: private_key
      )

      token_response = instance_double(Net::HTTPResponse, body: { access_token: "test-access-token" }.to_json)
      allow(Net::HTTP).to receive(:post_form).and_return(token_response)
    end

    it "delivers to devices with a push token, skipping tokenless devices and other owners' devices" do
      create(:device, owner: customer, push_token: "token-1")
      create(:device, owner: customer, push_token: nil)
      create(:device, push_token: "other-owner-token")

      requests = []
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start) { |*_args, &block| block.call(http) }
      allow(http).to receive(:request) do |request|
        requests << request
        instance_double(Net::HTTPOK).tap { |response| allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }
      end

      described_class.call(owner: customer, title: "Nova fatura", body: "Fulano, você possui uma nova fatura")

      expect(requests.size).to eq(1)
      expect(requests.first["Authorization"]).to eq("Bearer test-access-token")
      body = JSON.parse(requests.first.body)
      expect(body["message"]["token"]).to eq("token-1")
      expect(body["message"]["notification"]).to eq("title" => "Nova fatura", "body" => "Fulano, você possui uma nova fatura")
    end

    it "logs and continues without raising when FCM responds with an error" do
      create(:device, owner: customer, push_token: "token-1")

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start) { |*_args, &block| block.call(http) }
      error_response = instance_double(Net::HTTPBadRequest, body: "invalid token")
      allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(http).to receive(:request).and_return(error_response)

      expect(Rails.logger).to receive(:error).with(/FCM error/)
      expect { described_class.call(owner: customer, title: "Nova fatura", body: "oi") }.not_to raise_error
    end
  end
end
