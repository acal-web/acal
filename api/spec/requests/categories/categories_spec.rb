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

  describe "GET /categories/:id" do
    context "when successful" do
      it "returns the category" do
        category = create(:category, **valid_params[:category])

        get "/categories/#{category.id}"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => category.id,
          "name" => "Padrão",
          "description" => "Categoria padrão",
          "group" => "efetivo",
          "has_water_meter" => true,
          "water_price" => "12.5",
          "membership_price" => "30.0",
          "legacy_id" => nil,
          "tags" => [],
          "created_at" => category.created_at.as_json,
          "updated_at" => category.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent category" do
        get "/categories/00000000-0000-0000-0000-000000000000"
        expect(response).to have_http_status(:not_found)
      end

      it "returns not found for a soft deleted category" do
        category = create(:category, **valid_params[:category].merge(deleted_at: Time.current))

        get "/categories/#{category.id}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
