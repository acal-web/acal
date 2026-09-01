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

  describe "POST /categories" do
    context "when successful" do
      it "creates a category" do
        expect {
          post "/categories", params: valid_params
        }.to change(Category, :count).by(1)

        category = Category.last

        expect(response).to have_http_status(:created)
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

      it "accepts and returns a legacy_id" do
        post "/categories", params: { category: valid_params[:category].merge(legacy_id: 123) }

        category = Category.last

        expect(response).to have_http_status(:created)
        expect(category.legacy_id).to eq(123)
        expect(response.parsed_body["legacy_id"]).to eq(123)
      end

      it "strips leading and trailing whitespace from the name" do
        post "/categories", params: { category: valid_params[:category].merge(name: "  Padrão  ") }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["name"]).to eq("Padrão")
      end

      it "defaults has_water_meter to false when omitted" do
        post "/categories", params: { category: valid_params[:category].except(:has_water_meter) }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["has_water_meter"]).to eq(false)
      end

      it "allows the same name in a different group" do
        create(:category, **valid_params[:category])

        expect {
          post "/categories", params: { category: valid_params[:category].merge(group: "temporario") }
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "when it fails" do
      it "rejects a request without a name" do
        post "/categories", params: { category: valid_params[:category].except(:name) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end

      it "rejects a request without a group" do
        post "/categories", params: { category: valid_params[:category].except(:group) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("group" => [ "can't be blank", "is not included in the list" ])
      end

      it "rejects a request with an invalid group" do
        post "/categories", params: { category: valid_params[:category].merge(group: "invalido") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("group" => [ "is not included in the list" ])
      end

      it "rejects a request without a water price" do
        post "/categories", params: { category: valid_params[:category].except(:water_price) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("water_price" => [ "can't be blank", "is not a number" ])
      end

      it "rejects a request without a membership price" do
        post "/categories", params: { category: valid_params[:category].except(:membership_price) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("membership_price" => [ "can't be blank", "is not a number" ])
      end

      it "rejects a negative water price" do
        post "/categories", params: { category: valid_params[:category].merge(water_price: -1) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("water_price" => [ "must be greater than or equal to 0" ])
      end

      it "rejects a negative membership price" do
        post "/categories", params: { category: valid_params[:category].merge(membership_price: -1) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("membership_price" => [ "must be greater than or equal to 0" ])
      end

      it "rejects a duplicate category within the same group" do
        create(:category, **valid_params[:category])

        expect {
          post "/categories", params: valid_params
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end

      it "rejects a duplicate category with a different case within the same group" do
        create(:category, **valid_params[:category])

        expect {
          post "/categories", params: { category: valid_params[:category].merge(name: "PADRÃO") }
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end

      it "rejects a category with the same name as a soft-deleted category in the same group" do
        create(:category, **valid_params[:category].merge(deleted_at: Time.current))

        expect {
          post "/categories", params: valid_params
        }.not_to change(Category.unscoped, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without categories:manage" do
        sign_in_as(create(:user, role: "tesoureiro"))

        expect {
          post "/categories", params: valid_params
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
