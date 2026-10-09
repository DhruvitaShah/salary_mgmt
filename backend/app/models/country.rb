# Static list of supported countries (config/countries.yml). Countries are
# reference data, not user-editable records, so they are not a table.
class Country
  Entry = Struct.new(:code, :name, :currency, keyword_init: true)

  ALL = YAML.load_file(Rails.root.join("config/countries.yml"))
            .fetch("countries")
            .map { |c| Entry.new(code: c["code"], name: c["name"], currency: c["currency"]) }
            .freeze
  BY_CODE = ALL.index_by(&:code).freeze

  class << self
    def all = ALL

    def codes = BY_CODE.keys

    def find(code) = BY_CODE[code]

    def name_for(code) = BY_CODE[code]&.name || code
  end
end
