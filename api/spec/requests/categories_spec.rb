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

  describe "GET /categories" do
    context "when successful" do
      it "returns a paginated page of categories" do
        create_list(:category, 13)

        get "/categories"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["content"].size).to eq(10)
        expect(body.except("content")).to eq(
          "pageable" => { "pageNumber" => 0, "pageSize" => 10, "offset" => 0 },
          "hasNextPage" => true,
          "totalPages" => 2,
          "totalElements" => 13,
          "last" => false,
          "first" => true,
          "size" => 10,
          "number" => 0,
          "numberOfElements" => 10,
          "empty" => false
        )
      end

      it "excludes soft deleted categories" do
        post "/categories", params: valid_params
        id = response.parsed_body["id"]
        delete "/categories/#{id}"

        get "/categories"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "filters by name" do
        create(:category, name: "Padrão")
        create(:category, name: "Especial")

        get "/categories", params: { name: "padr" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Padrão" ])
      end
    end
  end

  describe "GET /categories/:id" do
    context "when successful" do
      it "returns the category" do
        post "/categories", params: valid_params
        id = response.parsed_body["id"]

        get "/categories/#{id}"

        category = Category.find(id)
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
        post "/categories", params: valid_params
        id = response.parsed_body["id"]
        delete "/categories/#{id}"

        get "/categories/#{id}"

        expect(response).to have_http_status(:not_found)
      end
    end
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
        post "/categories", params: valid_params

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
        post "/categories", params: valid_params

        expect {
          post "/categories", params: valid_params
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end

      it "rejects a duplicate category with a different case within the same group" do
        post "/categories", params: valid_params

        expect {
          post "/categories", params: { category: valid_params[:category].merge(name: "PADRÃO") }
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end
    end
  end

  describe "PATCH /categories/:id" do
    context "when successful" do
      it "updates the category" do
        post "/categories", params: valid_params
        id = response.parsed_body["id"]

        patch "/categories/#{id}", params: {
          category: {
            name: "Especial",
            description: "Nova",
            group: "fundador",
            has_water_meter: false,
            water_price: "5.00",
            membership_price: "10.00"
          }
        }

        category = Category.find(id)
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
        post "/categories", params: valid_params
        id = response.parsed_body["id"]

        patch "/categories/#{id}", params: { category: valid_params[:category].except(:name) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("name" => [ "can't be blank", "is too short (minimum is 3 characters)" ])
      end

      it "rejects a duplicate category" do
        post "/categories", params: valid_params
        post "/categories", params: { category: valid_params[:category].merge(name: "Outra") }
        id = response.parsed_body["id"]

        patch "/categories/#{id}", params: { category: valid_params[:category] }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "Category already exists")
      end
    end
  end

  describe "DELETE /categories/:id" do
    context "when successful" do
      it "soft deletes the category instead of removing it" do
        post "/categories", params: valid_params
        category = Category.last

        expect {
          delete "/categories/#{category.id}"
        }.not_to change(Category.unscoped, :count)

        expect(response).to have_http_status(:no_content)
        expect(category.reload.deleted_at).not_to be_nil
      end

      it "excludes the category from the default scope" do
        post "/categories", params: valid_params
        category = Category.last

        delete "/categories/#{category.id}"

        expect(Category.exists?(category.id)).to be(false)
      end
    end
  end
end
