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

    context "sorting" do
      it "sorts by name ascending by default" do
        create(:category, name: "Categoria C")
        create(:category, name: "Categoria A")
        create(:category, name: "Categoria B")

        get "/categories"

        expect(response.parsed_body["content"].map { |c| c["name"] })
          .to eq([ "Categoria A", "Categoria B", "Categoria C" ])
      end

      it "sorts by name descending when direction=desc" do
        create(:category, name: "Categoria C")
        create(:category, name: "Categoria A")
        create(:category, name: "Categoria B")

        get "/categories", params: { sort: "name", direction: "desc" }

        expect(response.parsed_body["content"].map { |c| c["name"] })
          .to eq([ "Categoria C", "Categoria B", "Categoria A" ])
      end

      # "group" is a reserved SQL word — the hash form of `order` is what gets
      # it quoted, so this would blow up if the column were interpolated raw.
      it "sorts by group" do
        create(:category, name: "Categoria A", group: "temporario")
        create(:category, name: "Categoria B", group: "efetivo")
        create(:category, name: "Categoria C", group: "fundador")

        get "/categories", params: { sort: "group" }

        expect(response.parsed_body["content"].map { |c| c["group"] })
          .to eq([ "efetivo", "fundador", "temporario" ])
      end

      it "ignores a sort column outside the allow-list" do
        create(:category, name: "Categoria C")
        create(:category, name: "Categoria A")

        get "/categories", params: { sort: "created_at" }

        expect(response.parsed_body["content"].map { |c| c["name"] })
          .to eq([ "Categoria A", "Categoria C" ])
      end
    end

    context "when unauthorized" do
      it "returns forbidden for a user without categories:records:read" do
        sign_in_as_customer(create(:customer))

        get "/categories"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
