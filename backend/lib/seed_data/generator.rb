require "set"

module SeedData
  # Generates a deterministic, realistic organisation. The same seed always
  # produces the same people and salaries, so demos and tests are repeatable.
  class Generator
    BATCH = 1_000
    SEED = 20_261_005

    def initialize(count: 10_000, seed: SEED, logger: nil)
      @count = count
      @rng = Random.new(seed)
      @logger = logger
      @emails = Hash.new(0)
    end

    def call
      departments = ensure_catalog
      generated = 0
      @count.times.each_slice(BATCH) do |indexes|
        rows = indexes.map { |i| build_person(i, departments) }
        insert_batch(rows)
        generated += rows.size
        @logger&.call("Seeded #{generated}/#{@count} employees")
      end
      generated
    end

    private

    def ensure_catalog
      Catalog::DEPARTMENTS.each_with_object({}) do |(name, config), map|
        dept = Department.find_or_create_by!(name: name)
        titles = config[:titles].map do |title, base, weight|
          { record: JobTitle.find_or_create_by!(department: dept, name: title), base: base, weight: weight }
        end
        map[name] = { record: dept, weight: config[:weight], titles: titles }
      end
    end

    def weighted(items, &weight)
      total = items.sum(&weight)
      roll = @rng.rand * total
      items.each do |item|
        roll -= weight.call(item)
        return item if roll <= 0
      end
      items.last
    end

    def build_person(index, departments)
      code, (_w, level, pool) = weighted(Catalog::COUNTRIES.to_a) { |_c, v| v[0] }
      dept = weighted(departments.values) { |d| d[:weight] }
      title = weighted(dept[:titles]) { |t| t[:weight] }
      country = Country.find(code)
      first = pick(Catalog::NAMES[pool][0])
      last = pick(Catalog::NAMES[pool][1])
      noise = 1 + (@rng.rand + @rng.rand + @rng.rand - 1.5) * 0.2
      amount = round_sig(title[:base] * level * Currency.rate(country.currency).to_f * noise)

      {
        employee_code: format("ACME-%05d", index + 1),
        name: "#{first} #{last}",
        email: unique_email(first, last),
        country_code: code,
        department_id: dept[:record].id,
        job_title_id: title[:record].id,
        salary_amount: amount,
        currency: country.currency,
        salary_usd: Currency.to_usd(amount, country.currency)
      }
    end

    def insert_batch(rows)
      now = Time.current
      Employee.insert_all!(rows.map { |r| r.merge(created_at: now, updated_at: now) })
    end

    def unique_email(first, last)
      base = "#{slug(first)}.#{slug(last)}"
      @emails[base] += 1
      "#{base}#{@emails[base] > 1 ? @emails[base] : ''}@acme.com"
    end

    def slug(text) = text.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.gsub(/[^a-z0-9]/, "")

    def pick(list) = list[@rng.rand(list.size)]

    # Round to 3 significant figures: 95,300 or 7,910,000 look like real salaries.
    def round_sig(value)
      magnitude = 10**[Math.log10([value, 1].max).floor - 2, 0].max
      (value / magnitude.to_f).round * magnitude
    end
  end
end
