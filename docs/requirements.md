# Requirements (frozen)

Status: **frozen.** The scope, stack and product direction below were confirmed with the assessor. Changes need a written reason in [technical-decisions.md](technical-decisions.md).

## Goal
A simple web application that lets ACME's HR Manager manage employee and salary data for about 10,000 full-time employees across several countries, find records quickly, and spot salary patterns. Priorities: simplicity, usability, correctness, maintainability.

## Confirmed clarifications
| Topic | Decision |
| --- | --- |
| Salary meaning | **Annual gross base salary**, full-time employees |
| Currency | Stored in the employee's **local currency** |
| Cross-country comparison | **Fixed, deterministic FX rates** (config file), no live API |
| Users | **Single HR Manager**, one login, no roles |
| Analytics | Dashboard plus a focused Salary Insights page |
| Data volume | **10,000 employees**, deterministic seed data |
| Stack | PostgreSQL, Ruby on Rails API, Angular |
| Out of scope | Payroll, tax, benefits/bonuses/allowances, live FX, RBAC, AI chat, attendance/leave, performance, recruitment, self-service, full HRMS |

## Primary user
HR Manager, non-technical. Plain labels (Annual Salary, Employee ID), search, filters, tables and simple charts. No query builders, no technical terms, friendly empty and error states.

## MVP screens (no more than these)
| # | Screen | In the navigation? |
| --- | --- | --- |
| 1 | Dashboard | Yes |
| 2 | Employees (directory) | Yes |
| 3 | Employee Details | No (opens from Employees) |
| 4 | Add / Edit Employee | No (buttons on Employees and Employee Details) |
| 5 | Salary Insights | Yes |

Navigation: **Dashboard, Employees, Salary Insights.** Plus Sign out.

## Functional requirements

| ID | Requirement | Where |
| --- | --- | --- |
| F1 | Dashboard: employee count, total annual salary cost, average and median salary, number of countries and departments; charts for employees by country, average salary by country, employees by department, average salary by department | `GET /dashboard` |
| F2 | Directory: search by name, employee ID, email; filter by country, department, job title; sort; server-side pagination; empty state "No employees found. Try changing your filters." | `GET /employees` |
| F3 | Employee Details: info, department, job title, country, current Annual Salary and currency | `GET /employees/:id` |
| F4 | Add and edit: name, Employee ID, email, country, department, job title, Annual Salary, currency | `POST/PATCH /employees` |
| F5 | Salary Insights: filters for **country, department, job title**; employee count, average, median and total salary cost; by country, department and job title; country × department grid; distribution | `GET /insights/*` |
| F6 | Choose the currency amounts are shown in on Dashboard and Insights (USD, INR, EUR, ...). INR uses lakh and crore (for example ₹18.4 L, ₹1,840 Cr) | Client-side, fixed rates |

## Salary and currency rules
* Salary is **annual gross base salary for a full-time employee**, stored in the employee's local currency.
* Cross-country reporting uses **fixed exchange rates** in `backend/config/exchange_rates.yml`, so reports are reproducible.
* A USD equivalent is stored with each employee so sorting and aggregation are plain indexed SQL. `bin/rails salary:recalculate_usd` refreshes it if rates are edited.
* **Never show a misleading number.** If an employee has a currency with no exchange rate, or the stored USD equivalents are out of date after a rate change, Dashboard and Insights refuse to calculate and say why. They do not skip those employees silently.
* Editing a salary or currency replaces the current value. No history is kept.


## Data model (summary)
| Table | Purpose |
| --- | --- |
| `employees` | Person, country, department, job title, **current** salary (amount, currency, USD equivalent) |
| `departments`, `job_titles` | Reference data; a job title belongs to one department |
| `users` | The HR login |
| (config) `exchange_rates.yml`, `countries.yml` | Fixed FX rates and supported countries |

Where this differs from the original plan (single `name` column, rates in config instead of a table) see [technical-decisions.md](technical-decisions.md).

## Validation rules
Name 2–80 characters. Employee ID 3–20 letters, numbers or dashes, unique. Email valid and unique (case-insensitive). Country and currency from the supported lists. Job title must belong to the department. Annual Salary greater than zero.

## Authentication
| ID | Requirement |
| --- | --- |
| A1 | One HR user signs in with email and password. No sign-up, no roles. |
| A2 | Everything except the sign-in page requires a valid session; API calls without one return 401. |
| A3 | Wrong credentials get one generic message (no hint whether the email exists). Five failures lock the account for 15 minutes. |
| A4 | Sessions end after 60 minutes idle or 12 hours total, and on sign out. After expiry the user is returned to sign-in and then to the page they were on. |
| A5 | The account is created from `HR_EMAIL` / `HR_PASSWORD` (12+ characters); production never has a default password. |

## Non-functional requirements
* Server-side filtering, sorting and pagination; each important index justified in [performance.md](performance.md).
* No N+1 queries on list endpoints (guarded by a spec).
* Fast, deterministic tests.
* Consistent JSON error format; friendly messages in the UI.
* Responsive layout, keyboard-accessible controls, light and dark themes.
* Seed data: 10,000 deterministic employees, realistic salaries per country and job title. `rails db:seed` always produces the same people and salaries.

## Out of scope
Payroll, tax, bonuses/allowances/benefits, attendance and leave, performance, recruitment, employee self-service, role/permission management, live exchange rates, natural-language or AI reporting, full HRMS.

## Assumptions
* A single HR Manager uses the system, so there is one login and no role or permission model. Password reset is an operator action (`RESET_HR_PASSWORD=true bin/rails users:ensure_hr`), not a self-service email flow.
* Ten countries and eight departments are supported out of the box (reference data in config and seeds).
* No delete function was requested, so employees are not deleted.
