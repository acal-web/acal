require "rails_helper"

RSpec.describe "Addresses", type: :request do
  let(:valid_params) { { address: { name: "Rua Main Street" } } }

  describe "GET /addresses" do
    context "pagination" do
      it "returns a paginated page of addresses" do
        create_list(:address, 13)

        get "/addresses"

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

      it "respects the page and size params" do
        create_list(:address, 25)

        get "/addresses", params: { page: 1, size: 10 }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["content"].size).to eq(10)
        expect(body.except("content")).to eq(
          "pageable" => { "pageNumber" => 1, "pageSize" => 10, "offset" => 10 },
          "hasNextPage" => true,
          "totalPages" => 3,
          "totalElements" => 25,
          "last" => false,
          "first" => false,
          "size" => 10,
          "number" => 1,
          "numberOfElements" => 10,
          "empty" => false
        )
      end
    end

    context "filtering" do
      it "filters by name" do
        create(:address, name: "Rua Main Street")
        create(:address, name: "Avenida Second Avenue")

        get "/addresses", params: { name: "main" }

        expect(response.parsed_body["content"].map { |a| a["name"] }).to eq([ "Rua Main Street" ])
      end
    end

    context "soft-deletion" do
      it "excludes soft deleted addresses" do
        post "/addresses", params: valid_params
        id = response.parsed_body["id"]
        delete "/addresses/#{id}"

        get "/addresses"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "returns only soft deleted addresses when active=false" do
        create(:address, name: "Rua Main Street")
        deleted = create(:address, name: "Avenida Excluída", deleted_at: Time.current)

        get "/addresses", params: { active: "false" }

        expect(response.parsed_body["content"].map { |a| a["id"] }).to eq([ deleted.id ])
      end

      it "returns active and soft deleted addresses when active=all" do
        active = create(:address, name: "Rua Main Street")
        deleted = create(:address, name: "Avenida Excluída", deleted_at: Time.current)

        get "/addresses", params: { active: "all" }

        expect(response.parsed_body["content"].map { |a| a["id"] }).to contain_exactly(active.id, deleted.id)
      end
    end

    context "sorting" do
      it "sorts by name ascending by default" do
        create(:address, name: "Rua C")
        create(:address, name: "Rua A")
        create(:address, name: "Rua B")

        get "/addresses"

        expect(response.parsed_body["content"].map { |a| a["name"] }).to eq([ "Rua A", "Rua B", "Rua C" ])
      end

      it "sorts by name descending when direction=desc" do
        create(:address, name: "Rua C")
        create(:address, name: "Rua A")
        create(:address, name: "Rua B")

        get "/addresses", params: { sort: "name", direction: "desc" }

        expect(response.parsed_body["content"].map { |a| a["name"] }).to eq([ "Rua C", "Rua B", "Rua A" ])
      end

      it "ignores a sort column outside the allow-list" do
        create(:address, name: "Rua C")
        create(:address, name: "Rua A")

        get "/addresses", params: { sort: "created_at" }

        expect(response.parsed_body["content"].map { |a| a["name"] }).to eq([ "Rua A", "Rua C" ])
      end
    end
  end
end
