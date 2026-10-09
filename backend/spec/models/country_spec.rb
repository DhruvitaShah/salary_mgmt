require "rails_helper"

RSpec.describe Country do
  it "finds a country and its currency" do
    expect(described_class.find("IN").currency).to eq("INR")
    expect(described_class.name_for("DE")).to eq("Germany")
  end

  it "only uses currencies that have an exchange rate" do
    expect(described_class.all.map(&:currency)).to all(satisfy { |c| Currency.valid?(c) })
  end
end
