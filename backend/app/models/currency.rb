# Fixed exchange rates loaded from config/exchange_rates.yml.
# Deterministic on purpose: reports are reproducible and need no external API.
class Currency
  # Raised instead of guessing when a currency has no rate.
  class MissingRate < StandardError; end

  # Raised when stored USD equivalents no longer match the configured rates.
  class StaleRates < StandardError; end

  RATES = YAML.load_file(Rails.root.join("config/exchange_rates.yml"))
              .fetch("rates")
              .transform_values { |v| BigDecimal(v.to_s) }
              .freeze

  class << self
    def codes = RATES.keys.sort

    def valid?(code) = RATES.key?(code)

    # Local-currency units per 1 USD.
    def rate(code)
      RATES.fetch(code) { raise MissingRate, "No exchange rate is configured for #{code}." }
    end

    def to_usd(amount, code)
      (BigDecimal(amount.to_s) / rate(code)).round(2)
    end
  end
end
