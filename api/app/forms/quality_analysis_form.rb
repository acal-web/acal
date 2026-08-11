class QualityAnalysisForm
  attr_reader :param_name, :reference_date, :required, :analyzed, :compliant, :legacy_id

  def initialize(param_name: nil, reference_date: nil, required: nil, analyzed: nil, compliant: nil, legacy_id: nil)
    @param_name = param_name
    @reference_date = reference_date
    @required = convert_to_integer(required)
    @analyzed = convert_to_integer(analyzed)
    @compliant = convert_to_integer(compliant)
    @legacy_id = legacy_id
  end

  def to_h
    {
      param_name:,
      reference_date:,
      required:,
      analyzed:,
      compliant:,
      legacy_id:
    }
  end

  private

  def convert_to_integer(value)
    return 0 if value.blank?
    value.to_s.strip.to_i
  rescue
    0
  end
end
