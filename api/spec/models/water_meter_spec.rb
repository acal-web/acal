require 'rails_helper'

RSpec.describe WaterMeter, type: :model do
  let(:customer) { create(:customer) }
  let(:address) { create(:address) }
  let(:category) { create(:category) }
  let(:connection) { create(:connection, customer: customer, address: address, category: category) }
  let(:invoice) { create(:invoice, connection: connection) }

  describe 'associations' do
    it 'belongs to invoice' do
      water_meter = create(:water_meter, invoice: invoice)
      expect(water_meter.invoice).to eq(invoice)
    end
  end

  describe 'validations' do
    it 'requires measured_at' do
      water_meter = build(:water_meter, invoice: invoice, measured_at: nil)
      expect(water_meter).not_to be_valid
      expect(water_meter.errors[:measured_at]).to be_present
    end

    it 'requires initial_reading' do
      water_meter = build(:water_meter, invoice: invoice, initial_reading: nil)
      expect(water_meter).not_to be_valid
      expect(water_meter.errors[:initial_reading]).to be_present
    end

    it 'requires final_reading' do
      water_meter = build(:water_meter, invoice: invoice, final_reading: nil)
      expect(water_meter).not_to be_valid
      expect(water_meter.errors[:final_reading]).to be_present
    end

    it 'validates initial_reading is greater than or equal to 0' do
      water_meter = build(:water_meter, invoice: invoice, initial_reading: -1)
      expect(water_meter).not_to be_valid
      expect(water_meter.errors[:initial_reading]).to be_present
    end

    it 'validates final_reading is greater than or equal to 0' do
      water_meter = build(:water_meter, invoice: invoice, final_reading: -1)
      expect(water_meter).not_to be_valid
      expect(water_meter.errors[:final_reading]).to be_present
    end

    it 'validates that final_reading is greater than or equal to initial_reading' do
      water_meter = build(:water_meter, invoice: invoice, initial_reading: 100, final_reading: 50)
      expect(water_meter).not_to be_valid
      expect(water_meter.errors[:final_reading]).to include('must be greater than or equal to initial_reading')
    end
  end

  describe '#total_consumption' do
    it 'calculates the total difference between final and initial readings' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 100, final_reading: 250)
      expect(water_meter.total_consumption).to eq(150)
    end

    it 'returns zero when readings are equal' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 1000, final_reading: 1000)
      expect(water_meter.total_consumption).to eq(0)
    end

    it 'calculates consumption within free tier' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 5000)
      expect(water_meter.total_consumption).to eq(5000)
    end

    it 'calculates consumption at exactly free tier limit' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 10000)
      expect(water_meter.total_consumption).to eq(10000)
    end

    it 'calculates consumption exceeding free tier' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 25000)
      expect(water_meter.total_consumption).to eq(25000)
    end

    it 'works with large meter readings' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 1000000, final_reading: 1050000)
      expect(water_meter.total_consumption).to eq(50000)
    end
  end

  describe '#consumption' do
    it 'returns excess consumption above 10000L free tier' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 15000)
      expect(water_meter.consumption).to eq(5000)
    end

    it 'returns zero if consumption is within free tier' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 5000)
      expect(water_meter.consumption).to eq(0)
    end

    it 'returns zero if consumption equals exactly the free tier' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 10000)
      expect(water_meter.consumption).to eq(0)
    end

    it 'charges only for usage above 10000L' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 5000, final_reading: 18000)
      expect(water_meter.total_consumption).to eq(13000)
      expect(water_meter.consumption).to eq(3000)
    end

    it 'returns zero when no water is consumed' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 5000, final_reading: 5000)
      expect(water_meter.consumption).to eq(0)
    end

    it 'handles large consumption with free tier deduction' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 1000000, final_reading: 1050000)
      expect(water_meter.total_consumption).to eq(50000)
      expect(water_meter.consumption).to eq(40000)
    end

    it 'never returns negative consumption' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 100, final_reading: 200)
      expect(water_meter.consumption).to be >= 0
    end
  end

  describe '#water_consumed_value' do
    it 'calculates value at R$ 4 per 1000 liters' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 15000)
      expect(water_meter.water_consumed_value).to be_within(0.01).of(20.0)
    end

    it 'returns zero when consumption is within free tier' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 0, final_reading: 5000)
      expect(water_meter.water_consumed_value).to eq(0)
    end

    it 'handles large consumption values' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 1000000, final_reading: 1050000)
      expect(water_meter.water_consumed_value).to be_within(0.01).of(160.0)
    end

    it 'calculates correctly with varying initial readings' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 5000, final_reading: 18000)
      expect(water_meter.water_consumed_value).to be_within(0.01).of(12.0)
    end

    it 'never returns a negative value' do
      water_meter = create(:water_meter, invoice: invoice, initial_reading: 100, final_reading: 200)
      expect(water_meter.water_consumed_value).to be >= 0
    end
  end
end
