# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrlCents, type: :model do
  it "format_reais 15500 is R$ 155,00" do
    expect(described_class.format_reais(15_500)).to eq("R$ 155,00")
  end

  it "format_reais 123456 groups thousands" do
    expect(described_class.format_reais(123_456)).to eq("R$ 1.234,56")
  end

  it "field_value 15500 is 155,00" do
    expect(described_class.field_value(15_500)).to eq("155,00")
  end

  it "field_value 0 is empty" do
    expect(described_class.field_value(0)).to eq("")
  end

  it "field_value nil is empty" do
    expect(described_class.field_value(nil)).to eq("")
  end
end
