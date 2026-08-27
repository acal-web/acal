class QualityAnalysesController < ApplicationController
  requires_permission "quality_analyses:read", only: %i[ index show ]
  requires_permission "quality_analyses:manage", only: %i[ create update destroy ]

  before_action :set_quality_analysis, only: %i[ show update destroy ]

  # GET /quality_analyses
  def index
    analyses = QualityAnalysis.filter_by_period(params[:year], params[:month]).ordered

    render json: paginate(analyses)
  end

  # GET /quality_analyses/1
  def show
    render json: @quality_analysis
  end

  # POST /quality_analyses
  def create
    @quality_analysis = QualityAnalysis.create!(reference_date:, param_name:, required:, analyzed:, compliant:)
    render json: @quality_analysis, status: :created, location: @quality_analysis
  end

  # PATCH/PUT /quality_analyses/1
  def update
    @quality_analysis.update!(reference_date:, param_name:, required:, analyzed:, compliant:)
    render json: @quality_analysis
  end

  # DELETE /quality_analyses/1
  def destroy
    @quality_analysis.soft_delete!
  end

  private
    def set_quality_analysis
      @quality_analysis = QualityAnalysis.find(params.expect(:id))
    end

    def quality_analysis_params
      params.expect(quality_analysis: [ :reference_date, :param_name, :required, :analyzed, :compliant ])
    end

    def reference_date
      quality_analysis_params[:reference_date]
    end

    def param_name
      quality_analysis_params[:param_name]
    end

    def required
      quality_analysis_params[:required]
    end

    def analyzed
      quality_analysis_params[:analyzed]
    end

    def compliant
      quality_analysis_params[:compliant]
    end
end
