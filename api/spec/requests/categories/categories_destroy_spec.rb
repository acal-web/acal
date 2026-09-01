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
end
