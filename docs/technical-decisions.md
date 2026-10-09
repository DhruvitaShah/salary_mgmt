# Technical decisions

Each decision: what, why, what it costs, and when to revisit.

## Platform

### PostgreSQL
**Why:** the product is mostly filtering, grouping and medians over 10,000 rows. PostgreSQL has `PERCENTILE_CONT` (true medians in SQL), trigram indexes (fast "contains" search on names, emails, IDs), partial and composite indexes, and exact `numeric` for money.
**Cost:** needs a database server (a managed one is a click on most hosts).
**Revisit:** not needed at this scale.

### Rails API (not a full-stack Rails app)
**Why:** the brief asks for RESTful JSON APIs with RSpec. Rails gives validations, migrations, strong parameters and a fast route to a well-tested API. Business rules live in models and small service objects, so controllers stay thin.
**Cost:** two codebases to run locally.

### Angular with Angular Material
**Why:** the brief asks for Angular and a component library. Material gives accessible selects, form fields, paginator and sorting without custom work. Standalone components and signals keep state simple; routes are lazy-loaded.
**Cost:** Material adds weight; charts are plain HTML/SVG, so no chart library is added on top.

### One deployable (Rails serves the built Angular app)
**Why:** same origin means no CORS configuration, cookies work simply, and there is one service and one database to deploy and monitor.
**Cost:** frontend and backend release together. Splitting later only needs a different static host and CORS settings (already in place for local development).

## Data

### Salary stored in local currency
**Why:** HR thinks in the currency people are paid in; converting at entry would lose the real number and change when rates change.
**Cost:** cross-country comparison needs conversion (next).

### Fixed exchange rates, no live FX
**Why:** reports must be reproducible: the same data gives the same totals today and next month. A live API adds a dependency, an outage mode and numbers that move while HR is looking at them. The assessor confirmed fixed rates.
**How:** rates live in `backend/config/exchange_rates.yml`. Each employee stores a **USD equivalent** computed from them, so sorting and totals across currencies are plain indexed SQL. The dashboard and insights convert from USD to the display currency using the same fixed rates.
**Safety:** an audit (`ExchangeRateAudit`) runs before every report. A currency with no rate, or stored USD equivalents that no longer match the config, stops the report with a plain message; it never skips people or mixes old and new rates. `bin/rails salary:check_rates` and `salary:recalculate_usd` are the operator tools.
**Cost:** editing a rate needs a deploy plus a recalculation.

### Rates in a config file instead of an `exchange_rates` table
The original plan sketched an `ExchangeRate(from_currency, to_currency, rate, effective_date)` table. A table would allow rate history and editing through the UI, but editing rates was not requested and the brief wants a deterministic configuration. A file is reviewed in git, cannot be changed by accident at runtime, and needs no admin screen. **Revisit** if finance wants rates by effective date (then add the table and keep `salary_usd` as a cached value).

### One `name` column instead of `first_name` and `last_name`
Names do not split reliably (single names, family-name-first, multi-word given names; the seed data includes such names). The directory needs only display and search, both of which work on one field. **Revisit** if HR needs to sort by last name or mail-merge: add the two columns and backfill.

### Countries and currencies as configuration
Ten countries is fixed reference data with no screen to edit it. `departments` and `job_titles` are tables because employees reference them and HR may eventually maintain them.

### Money as `decimal(15,2)`
Exact in PostgreSQL and Ruby (`BigDecimal`). JSON carries numbers, which are exact for amounts of this size.

## Product


### Display currency (Dashboard and Insights)
HR in India reads ₹ in lakh and crore; HR elsewhere reads USD or EUR. The server always reports USD; the browser converts with the same fixed rates, so the choice changes presentation, never the underlying numbers. The salary distribution chart keeps its fixed $20k USD-equivalent bands (so bars never change shape) but its axis, band labels, tooltips and median are converted to the chosen currency.

## Security

### Single HR account, cookie session, no roles
The brief says one HR Manager and no role management. A server-side session in an encrypted `HttpOnly` cookie (not a token in `localStorage`), a CSRF token for writes, lockout after five failures, idle and absolute expiry. See [architecture.md](architecture.md#authentication-and-session-security).
**Cost:** no self-service password reset; the operator resets it.

### No RBAC
One user, one role. A permission model would add tables, screens and tests with nothing to protect.

## What was left out on purpose
| Not built | Why |
| --- | --- |
| Live exchange-rate API | Reproducibility; confirmed out of scope |
| AI or natural-language reporting | Out of scope; filters cover the needed questions |
| Role-based access control | Single HR user |
| Payroll, tax, benefits, bonuses, leave, performance, recruitment | Out of scope; this is salary data management and analysis |
| Delete employee | Not requested |
| Chart library | Two chart types, drawn directly; fewer dependencies |
