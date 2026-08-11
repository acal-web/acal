class CategoryForm
  attr_reader :name, :description, :group, :has_water_meter, :water_price, :membership_price, :legacy_id

  def initialize(
    name: nil,
    description: nil,
    group: nil,
    has_water_meter: false,
    water_price: nil,
    membership_price: nil,
    legacy_id: nil
  )
    @name = name&.strip
    @description = description
    @group = group
    @has_water_meter = has_water_meter
    @water_price = water_price
    @membership_price = membership_price
    @legacy_id = legacy_id
  end

  def to_h
    {
      name:,
      description:,
      group:,
      has_water_meter:,
      water_price:,
      membership_price:,
      legacy_id:
    }
  end
end
