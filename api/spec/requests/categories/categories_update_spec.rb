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

  describe "PATCH /categories/:id" do
    context "when successful" do
      it "updates the category" do
        category = create(:category, **valid_params[:category])

        patch "/categories/#{category.id}", params: {
          category: {
            name: "Especial",
            description: "Nova",
            group: "fundador",
            has_water_meter: false,
            water_price: "5.00",
            membership_price: "10.00"
          }
        }

        category.reload
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => category.id,
          "name" => "Especial",
          "description" => "Nova",
          "group" => "fundador",
          "has_water_meter" => false,
          "water_price" => "5.0",
          "membership_price" => "10.0",
          "legacy_id" => nil,
          "tags" => [],
          "created_at" => category.created_at.as_json,
          "updated_at" => category.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "rejects a request without a name" do
        category = create(:category, **valid_params[:category])

        patch "/categories/#{category.id}", params: { category: valid_params[:category].except(:name) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end

      it "rejects a duplicate category within the same group" do
        create(:category, **valid_params[:category])
        other = create(:category, **valid_params[:category].merge(name: "Outra"))

        patch "/categories/#{other.id}", params: { category: valid_params[:category] }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end

      it "returns not found for a nonexistent category" do
        patch "/categories/00000000-0000-0000-0000-000000000000", params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without categories:manage" do
        category = create(:category, **valid_params[:category])
        sign_in_as(create(:user, role: "tesoureiro"))

        patch "/categories/#{category.id}", params: { category: valid_params[:category].merge(name: "Especial") }

        expect(response).to have_http_status(:forbidden)
        expect(category.reload.name).to eq("Padrão")
      end
    end
  end
end
