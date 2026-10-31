# Methodology & KPI Definitions

## Analysis workflow

1. Load relational source tables into PostgreSQL.
2. Validate primary keys, foreign keys, row counts, nulls, and duplicate request IDs.
3. Join request activity to employee, department, model, and token usage data.
4. Calculate request-level cost from model-specific input/output rates.
5. Aggregate metrics by department, model, month, and request status.
6. Reconcile aggregate token totals against request-level totals.
7. Export analysis outputs using Python.
8. Build Power BI measures and dashboard pages.
9. Translate findings into business recommendations.

## KPI definitions

### Total Requests
Distinct count of `ai_requests.request_id`.

### Total Input Tokens
Sum of `token_usage.input_tokens`.

### Total Output Tokens
Sum of `token_usage.output_tokens`.

### Total Tokens
Input tokens + output tokens.

### AI Cost (USD)
For each request:

`((input_tokens × input_rate_per_million_usd) + (output_tokens × output_rate_per_million_usd)) / 1,000,000`

Sum request-level cost for the selected reporting scope.

### Request Success Rate
`Successful Requests / Total Requests`

Use `ai_requests.request_status = 'Success'` for request execution success.

### Estimated Labor Value
`time_saved_minutes × hourly_labor_cost_usd / 60`

This is an estimate based on reported time saved and an hourly labor-cost assumption. It is not automatically realized cash savings.

### Estimated ROI
`(Estimated Labor Value - AI Cost) / AI Cost`

Only calculate when AI cost is greater than zero and both values refer to the same date range, population, and filter context. Format as a percentage in Power BI; do not multiply by 100 if the measure is formatted as Percentage.

## Data validation controls

- Confirm request IDs are unique at request grain.
- Check token usage coverage for requests.
- Check model rate fields are populated and non-negative.
- Reconcile total tokens across request-level and grouped outputs.
- Reconcile total AI cost across model, department, and month summaries.
- Confirm date filters apply consistently to requests, token usage, outcomes, and budgets.
- Aggregate budget at department-month grain to prevent duplication.
- Treat missing token rows as data-quality exceptions, not automatically as zero.
