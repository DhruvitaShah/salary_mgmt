# Salary Manager

A web application for HR Manager to replace Excel-based salary tracking for about 10,000 full-time employees in several countries. It covers employee records, a dashboard, and filterable salary insights.

* **Backend:** Ruby on Rails 7.2 (API only), PostgreSQL, RSpec
* **Frontend:** Angular 19 with Angular Material
* **Deployment:** one Docker image; Rails serves the compiled Angular app and the JSON API from the same origin

## Sign in

There is one login, for the HR Manager. There is no sign-up page; the account is created from environment variables.

| Where | How the account is created |
| --- | --- |
| Local development | `bin/rails db:seed` creates HR. |

Security behaviour: passwords are stored as bcrypt digests; five wrong passwords lock the account for 15 minutes; sessions end after 60 minutes idle or 12 hours in total; the session cookie is HttpOnly, SameSite=Lax and Secure in production; state-changing requests need a CSRF token header (handled automatically by the Angular app). Every `/api/v1` endpoint except sign-in returns 401 without a session.

## Run it locally

Prerequisites: Ruby 3.3, Node 22, PostgreSQL 16 (or `docker compose up -d db`).

```bash
# 1. API + database
cd backend
bundle install
bin/rails db:prepare          # creates the DB, runs migrations
bin/rails db:seed             # HR login + 10,000 deterministic employees (~10 s). SEED_COUNT=500 for a small set
bin/rails server              # http://localhost:3000

# 2. Angular dev server (proxies /api to :3000)
cd ../frontend
npm install
npm start                     # http://localhost:4200
```

Check exchange-rate health any time with `bin/rails salary:check_rates`.

Then open http://localhost:4200 and sign in with the development account above.

Database connection defaults to `postgres/postgres@localhost`; override with `DB_HOST`, `DB_USER`, `DB_PASSWORD`.

## Tests

```bash
cd backend && bundle exec rspec        # models, services, query object, API request specs
cd frontend && npm test                # Karma/Jasmine in headless Chrome (set CHROME_BIN if needed)
```

## Deploy

`render.yaml` is a Render Blueprint (web service + Postgres). Any host that runs a Docker image works. Serve it over HTTPS (the session cookie is marked Secure). On first boot the container runs `db:prepare` and seeds 10,000 employees (set `SEED_ON_BOOT=false` to skip).

## Screens

| Screen | What it does |
| --- | --- |
| Dashboard | Employees, total salary cost, average and median salary, countries, departments; employees and average/median salary by country and department. Amounts can be shown in any supported currency (INR in lakh and crore). |
| Employees | Search by name, ID or email; filter by country, department, job title; sortable, server-side pagination. |
| Employee details | Info, current Annual Salary in local currency (and USD equivalent). |
| Add / edit | Validated form. Saving a new salary replaces the current amount. |
| Salary Insights | By country, department, job title; country × department grid; salary distribution. Filter by country, department and job title. |

## API

All under `/api/v1`. Errors are JSON: `{ "error": { "code", "message", "details" } }`.

| Method and path | Purpose |
| --- | --- |
| `GET /employees?q&country&department_id&job_title_id&sort&direction&page&per_page` | Paginated list (`sort`: name, employee_code, department, job_title, country, salary) |
| `GET /employees/:id` | Employee |
| `POST /employees` | Create (`{ "employee": {...} }`) |
| `PATCH /employees/:id` | Update employee, including salary or currency |
| `GET /lookups` | Countries, currencies and rates, departments with job titles |
| `GET /dashboard` | Summary plus by-country and by-department figures |
| `GET /insights/{by_country,by_department,by_job_title,matrix,distribution}?country&department_id&job_title_id` | Filterable reports; 503 with a plain message if a currency has no exchange rate or rates are out of date |
| `POST /session`, `GET /session`, `DELETE /session` | Sign in (`{email, password}`), who am I, sign out. Everything else needs a session; 401 otherwise |
| `GET /up` | Health check (public) |

## Documentation

* [Requirements (frozen)](docs/requirements.md)
* [Technical decisions and trade-offs](docs/technical-decisions.md)
* [Deployment and post-deploy checklist](docs/deployment.md)
