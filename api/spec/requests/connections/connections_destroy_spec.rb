require "rails_helper"

RSpec.describe "Connections", type: :request do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }
  let(:valid_params) do
    { connection: { customer_id: customer.id, address_id: address.id, category_id: category.id, number: 1 } }
  end

  describe "DELETE /connections/:id" do
    context "when successful" do
      it "soft deletes the connection instead of removing it" do
        post "/connections", params: valid_params
        connection = Connection.last

        expect {
          delete "/connections/#{connection.id}"
        }.not_to change(Connection.unscoped, :count)

        expect(response).to have_http_status(:no_content)
        expect(connection.reload.deleted_at).not_to be_nil
      end

      it "excludes the connection from the default scope" do
        post "/connections", params: valid_params
        connection = Connection.last

        delete "/connections/#{connection.id}"

        expect(Connection.exists?(connection.id)).to be(false)
      end
    end
  end
end
