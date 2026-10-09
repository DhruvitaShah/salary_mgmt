module QueryCounter
  IGNORED = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i

  # Number of SQL statements run inside the block (ignores schema lookups,
  # cached repeats and transaction bookkeeping).
  def count_queries(&block)
    count = 0
    counter = lambda do |*, payload|
      next if payload[:name] == "SCHEMA" || payload[:cached] || payload[:sql].match?(IGNORED)

      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

RSpec.configure { |c| c.include QueryCounter, type: :request }
