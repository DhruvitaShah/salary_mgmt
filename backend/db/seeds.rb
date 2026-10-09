user = User.find_or_initialize_by(
        email: 'shahdhruvita2012@gmail.com',
        name: 'Dhruvita Shah',
        failed_attempts: 0, locked_until: nil)
user.password = 'Dhruvita@123'
user.save!
user
puts "HR login: #{user.email}"

# 10,000 deterministic sample employees.
# Re-running is safe: it skips when employees already exist unless FORCE=1.
count = ENV.fetch("SEED_COUNT", 10_000).to_i

if Employee.exists? && ENV["FORCE"] != "1"
  puts "Employees already present (#{Employee.count}); skipping. Use FORCE=1 to reseed."
else
  if ENV["FORCE"] == "1"
    Employee.delete_all
  end
  started = Time.current
  total = SeedData::Generator.new(count: count, logger: ->(msg) { puts msg }).call
  puts "Seeded #{total} employees in #{(Time.current - started).round(1)}s"
end
