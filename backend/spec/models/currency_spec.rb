require "rails_helper"

RSpec.describe Currency do
  it "lists supported codes" do
    expect(described_class.codes).to include("USD", "INR", "EUR", "JPY")
  end

  it "converts using the fixed rate (local units per USD)" do
    expect(described_class.to_usd(8_320_000, "INR")).to eq(100_000)
    expect(described_class.to_usd(100_000, "USD")).to eq(100_000)
    expect(described_class.to_usd(15_000_000, "JPY")).to eq(100_000)
  end

  it "rounds to cents" do
    expect(described_class.to_usd(100_000, "EUR")).to eq(BigDecimal("108695.65"))
  end

  it "rejects unknown currencies" do
    expect(described_class.valid?("XXX")).to be(false)
    expect { described_class.rate("XXX") }.to raise_error(Currency::MissingRate, /XXX/)
  end
end
