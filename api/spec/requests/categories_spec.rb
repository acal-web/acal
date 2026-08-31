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

  describe "GET /categories" do
    context "when successful" do
      it "returns a paginated page of categories" do
        categories = create_list(:category, 13)

        get "/categories"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        returned_ids = body["content"].map { |c| c["id"] }
        page = returned_ids.map { |id| categories.find { |c| c.id == id } }

        expect(body).to eq(
          "content" => page.map { |category|
            {
              "id" => category.id,
              "name" => category.name,
              "description" => category.description,
              "group" => category.group,
              "has_water_meter" => category.has_water_meter,
              "water_price" => category.water_price.to_s,
              "membership_price" => category.membership_price.to_s,
              "legacy_id" => category.legacy_id,
              "tags" => category.tags,
              "created_at" => category.created_at.as_json,
              "updated_at" => category.updated_at.as_json,
              "deleted_at" => category.deleted_at
            }
          },
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
        create(:category, **valid_params[:category].merge(deleted_at: Time.current))

        get "/categories"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "filters by name" do
        create(:category, name: "Padrão")
        create(:category, name: "Especial")

        get "/categories", params: { name: "padr" }

        expect(response.parsed_body["content"].map { |c| c["name"] }).to eq([ "Padrão" ])
      end

      it "returns only soft deleted categories when active=false" do
        create(:category, **valid_params[:category])
        deleted = create(:category, **valid_params[:category].merge(name: "Excluída", deleted_at: Time.current))

        get "/categories", params: { active: "false" }

        expect(response.parsed_body["content"].map { |c| c["id"] }).to eq([ deleted.id ])
      end

      it "returns active and soft deleted categories when active=all" do
        active = create(:category, **valid_params[:category])
        deleted = create(:category, **valid_params[:category].merge(name: "Excluída", deleted_at: Time.current))

        get "/categories", params: { active: "all" }

        expect(response.parsed_body["content"].map { |c| c["id"] }).to contain_exactly(active.id, deleted.id)
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

      it "rejects a duplicate category" do
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

  describe "DELETE /categories/:id" do
    context "when successful" do
      it "soft deletes the category instead of removing it" do
        category = create(:category, **valid_params[:category])

        expect {
          delete "/categories/#{category.id}"
        }.not_to change(Category.unscoped, :count)

        expect(response).to have_http_status(:no_content)
        expect(category.reload.deleted_at).not_to be_nil
      end

      it "excludes the category from the default scope" do
        category = create(:category, **valid_params[:category])

        delete "/categories/#{category.id}"

        expect(Category.exists?(category.id)).to be(false)
      end
    end

    context "when it fails" do
      it "returns not found for a nonexistent category" do
        delete "/categories/00000000-0000-0000-0000-000000000000"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without categories:manage" do
        category = create(:category, **valid_params[:category])
        sign_in_as(create(:user, role: "tesoureiro"))

        delete "/categories/#{category.id}"

        expect(response).to have_http_status(:forbidden)
        expect(category.reload.deleted_at).to be_nil
      end
    end
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
