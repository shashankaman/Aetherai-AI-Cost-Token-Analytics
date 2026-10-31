# Data Dictionary

The project schema contains seven relational tables.

| Table | Grain | Key fields | Purpose |
|---|---|---|---|
| departments | One row per department | department_id, department_name, monthly_budget_usd | Department reference |
| employees | One row per employee | employee_id, department_id, role | Employee-to-department mapping |
| ai_models | One row per model | model_id, provider, model_name, input_rate_per_million_usd, output_rate_per_million_usd, model_tier | Model and pricing reference |
| ai_requests | One row per request | request_id, employee_id, model_id, request_time, task_type, request_status, latency_ms | Request activity |
| token_usage | One row per request (expected) | request_id, input_tokens, output_tokens | Token consumption |
| task_outcomes | One row per request (expected) | request_id, task_type, task_successful, time_saved_minutes, hourly_labor_cost_usd | Business outcome estimates |
| department_budgets | One row per department per month | department_id, budget_month, budget_amount_usd | Monthly department budget |

## Relationships

- departments 1-to-many employees
- employees 1-to-many ai_requests
- ai_models 1-to-many ai_requests
- ai_requests 1-to-1 token_usage when request_id is unique
- ai_requests 1-to-1 task_outcomes when request_id is unique
- departments 1-to-many department_budgets

## Modeling cautions

- Verify uniqueness of `request_id` in token_usage and task_outcomes before joining.
- Avoid joining multiple one-to-many tables in a way that multiplies request rows.
- Aggregate budget at department-month grain before comparing it with monthly actual spend.
- Do not multiply a monthly budget by the number of requests in that month.
- Create a date-only request date for relationship to a calendar table if the report uses daily/monthly date analysis.
- `ai_requests.request_status` is request execution status; `task_outcomes.task_successful` is business task success.
