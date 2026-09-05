require "rails_helper"

RSpec.describe "QualityAnalyses", type: :request do
  let(:valid_params) do
    {
      quality_analysis: {
        reference_date: "2026-08-01",
        param_name: "Cloro Residual",
        required: 1,
        analyzed: 1,
        compliant: 1
      }
    }
  end

  describe "GET /quality_analyses" do
    context "when successful" do
      it "returns a paginated page of quality analyses" do
        create_list(:quality_analysis, 13)

        get "/quality_analyses"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["content"].size).to eq(10)
        expect(body["totalElements"]).to eq(13)
      end

      it "excludes soft deleted quality analyses" do
        post "/quality_analyses", params: valid_params
        id = response.parsed_body["id"]
        delete "/quality_analyses/#{id}"

        get "/quality_analyses"

        expect(response.parsed_body["content"]).to eq([])
      end

      it "orders by reference_date descending, then param_name ascending" do
        create(:quality_analysis, reference_date: "2026-07-01", param_name: "Turbidez")
        create(:quality_analysis, reference_date: "2026-08-01", param_name: "Cor Aparente")
        create(:quality_analysis, reference_date: "2026-08-01", param_name: "Cloro Residual")

        get "/quality_analyses"

        expect(response.parsed_body["content"].map { |a| [ a["reference_date"], a["param_name"] ] }).to eq(
          [ [ "2026-08-01", "Cloro Residual" ], [ "2026-08-01", "Cor Aparente" ], [ "2026-07-01", "Turbidez" ] ]
        )
      end

      it "filters by year and month" do
        create(:quality_analysis, reference_date: "2026-08-01", param_name: "Turbidez")
        create(:quality_analysis, reference_date: "2026-07-01", param_name: "Turbidez")

        get "/quality_analyses", params: { year: 2026, month: 8 }

        expect(response.parsed_body["content"].map { |a| a["reference_date"] }).to eq([ "2026-08-01" ])
      end
    end
  end

  describe "GET /quality_analyses/:id" do
    it "returns a single quality analysis" do
      post "/quality_analyses", params: valid_params
      id = response.parsed_body["id"]

      get "/quality_analyses/#{id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(id)
    end
  end

  describe "POST /quality_analyses" do
    context "when successful" do
      it "creates a quality analysis" do
        expect {
          post "/quality_analyses", params: valid_params
        }.to change(QualityAnalysis, :count).by(1)

        analysis = QualityAnalysis.last

        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(
          "id" => analysis.id,
          "reference_date" => "2026-08-01",
          "param_name" => "Cloro Residual",
          "required" => 1,
          "analyzed" => 1,
          "compliant" => 1,
          "legacy_id" => nil,
          "created_at" => analysis.created_at.as_json,
          "updated_at" => analysis.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "rejects a request without a reference_date" do
        post "/quality_analyses", params: { quality_analysis: valid_params[:quality_analysis].except(:reference_date) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("reference_date" => [ "can't be blank" ])
      end

      it "rejects a request with a param_name outside the allowed list" do
        post "/quality_analyses", params: { quality_analysis: valid_params[:quality_analysis].merge(param_name: "Outro") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("param_name" => [ "is not included in the list" ])
      end

      it "rejects a request without required/analyzed/compliant" do
        post "/quality_analyses", params: { quality_analysis: valid_params[:quality_analysis].except(:required, :analyzed, :compliant) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq(
          "required" => [ "can't be blank", "is not a number" ],
          "analyzed" => [ "can't be blank", "is not a number" ],
          "compliant" => [ "can't be blank", "is not a number" ]
        )
      end

      it "rejects negative values" do
        post "/quality_analyses", params: { quality_analysis: valid_params[:quality_analysis].merge(analyzed: -1) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("analyzed" => [ "must be greater than or equal to 0" ])
      end

      it "rejects a duplicate param_name within the same reference month" do
        post "/quality_analyses", params: valid_params

        expect {
          post "/quality_analyses", params: valid_params
        }.not_to change(QualityAnalysis, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "QualityAnalysis already exists")
      end
    end
  end

  describe "PATCH /quality_analyses/:id" do
    context "when successful" do
      it "updates the quality analysis" do
        post "/quality_analyses", params: valid_params
        id = response.parsed_body["id"]

        patch "/quality_analyses/#{id}", params: {
          quality_analysis: { reference_date: "2026-09-01", param_name: "Turbidez", required: 2, analyzed: 2, compliant: 1 }
        }

        analysis = QualityAnalysis.find(id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "id" => analysis.id,
          "reference_date" => "2026-09-01",
          "param_name" => "Turbidez",
          "required" => 2,
          "analyzed" => 2,
          "compliant" => 1,
          "legacy_id" => nil,
          "created_at" => analysis.created_at.as_json,
          "updated_at" => analysis.updated_at.as_json,
          "deleted_at" => nil
        )
      end
    end

    context "when it fails" do
      it "rejects a duplicate param_name within the same reference month" do
        post "/quality_analyses", params: valid_params
        post "/quality_analyses", params: { quality_analysis: valid_params[:quality_analysis].merge(param_name: "Turbidez") }
        id = response.parsed_body["id"]

        patch "/quality_analyses/#{id}", params: { quality_analysis: valid_params[:quality_analysis] }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("code" => 1001, "message" => "QualityAnalysis already exists")
      end
    end
  end

  describe "DELETE /quality_analyses/:id" do
    context "when successful" do
      it "soft deletes the quality analysis instead of removing it" do
        post "/quality_analyses", params: valid_params
        analysis = QualityAnalysis.last

        expect {
          delete "/quality_analyses/#{analysis.id}"
        }.not_to change(QualityAnalysis.unscoped, :count)

        expect(response).to have_http_status(:no_content)
        expect(analysis.reload.deleted_at).not_to be_nil
      end

      it "excludes the quality analysis from the default scope" do
        post "/quality_analyses", params: valid_params
        analysis = QualityAnalysis.last

        delete "/quality_analyses/#{analysis.id}"

        expect(QualityAnalysis.exists?(analysis.id)).to be(false)
      end
    end
  end
end
