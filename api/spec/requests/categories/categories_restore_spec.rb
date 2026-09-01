require "rails_helper"

RSpec.describe "Categories", type: :request do
  let(:valid_params) do
    {
      category: {
        name: "Padrão",
        description: "Categoria padrão",
        group: "efetivo",
        has_water_meter: true,
        water_price: "12.50",
        membership_price: "30.00"
      }
    }
  end

  describe "PATCH /categories/:id/restore" do
    context "when successful" do
      it "restores a soft deleted category" do
        category = create(:category, **valid_params[:category].merge(deleted_at: Time.current))

        patch "/categories/#{category.id}/restore"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["deleted_at"]).to be_nil
        expect(category.reload.deleted_at).to be_nil
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent category" do
        patch "/categories/00000000-0000-0000-0000-000000000000/restore"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without categories:manage" do
        category = create(:category, **valid_params[:category].merge(deleted_at: Time.current))
        sign_in_as(create(:user, role: "tesoureiro"))

        patch "/categories/#{category.id}/restore"

        expect(response).to have_http_status(:forbidden)
        expect(category.reload.deleted_at).not_to be_nil
      end
    end
  end
end
