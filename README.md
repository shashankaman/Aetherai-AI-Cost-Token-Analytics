# AetherAI — AI Cost & Token Usage Analytics

An end-to-end data analytics portfolio project analyzing AI request activity, token consumption, model-level API costs, department usage, and request reliability across January–December 2025.

## Project at a glance

| Item | Details |
|---|---|
| Project | AetherAI — AI Cost & Token Usage Analytics |
| Domain | AI / SaaS usage analytics |
| Analysis period | January–December 2025 |
| Database | PostgreSQL |
| Analysis | Python |
| Dashboard | Power BI |
| Dataset size | 12,000 AI requests |
| Total tokens | 30,450,854 |
| Estimated AI API cost from token rates | Approximately $37.90 |

## Business problem

As organizations adopt AI tools across departments, decision-makers need visibility into how frequently AI is used, how many tokens are consumed, how much each model costs, which departments drive usage, and whether requests are completing successfully.

AetherAI simulates this business problem and builds an analytics workflow to turn request-level data into cost, usage, reliability, and business-value reporting.

## Objectives

- Measure AI request volume and token consumption.
- Calculate AI cost using model-specific input and output token rates.
- Compare usage and cost across AI models, departments, and months.
- Monitor request success, errors, and timeouts.
- Build a Power BI dashboard for executive and operational decision-making.
- Identify cost optimization and reliability improvement opportunities.

## Technology stack

- **PostgreSQL / pgAdmin:** relational data storage, joins, aggregations, and SQL analysis.
- **Python:** data preparation, analysis, validation, and export.
- **Power BI:** KPI measures, data modeling, interactive reporting, and business storytelling.

## Dataset structure

The project uses seven relational tables:

1. `departments` — department names and department-level monthly budget reference.
2. `employees` — employees mapped to departments.
3. `ai_models` — AI model/provider details and input/output token rates.
4. `ai_requests` — request timestamps, task types, statuses, employee and model references.
5. `token_usage` — input and output tokens per request.
6. `task_outcomes` — task success, estimated time saved, and hourly labor cost.
7. `department_budgets` — department budgets by month.

## Key metrics and definitions

- **Total Requests:** distinct count of `request_id`.
- **Total Tokens:** input tokens + output tokens.
- **AI Cost (USD):** `((input_tokens × input_rate_per_million_usd) + (output_tokens × output_rate_per_million_usd)) / 1,000,000`.
- **Request Success Rate:** successful request count / total request count.
- **Estimated Labor Value:** `time_saved_minutes × hourly_labor_cost_usd / 60`.
- **Estimated ROI:** `(estimated_labor_value - AI_cost) / AI_cost`, only when AI cost is greater than zero and both values use the same population and reporting period.

`ai_requests.request_status` measures request execution status. `task_outcomes.task_successful` measures business task success. These are different concepts and should not be treated as interchangeable.

## Verified findings

- 12,000 unique AI requests were analyzed.
- Total token consumption was **30,450,854**: 21,235,456 input tokens and 9,215,398 output tokens.
- Approximate total AI cost was **$37.90**.
- 11,476 requests were successful, giving a **95.63% request success rate**.
- There were 348 errors (**2.90%**) and 176 timeouts (**1.47%**).
- Aether-Pro generated approximately **$30.17**, or **79.59%** of total AI cost, while handling **26.05%** of requests.
- Customer Support had the highest request volume (3,395) and highest department cost (approximately $10.65). Its cost share (28.09%) was close to its request share (28.29%).
- January was the highest-cost month (approximately $3.56); February was the lowest (approximately $2.83). Monthly cost fluctuated without a consistent upward trend.
- Department-level token totals reconcile with request-level token totals.

## Business insights and recommendations

### 1. Model cost concentration
**Insight:** Aether-Pro handled 26.05% of requests but contributed 79.59% of total AI cost.

**Recommendation:** Review the task types routed to Aether-Pro. Pilot lower-cost models for suitable, lower-complexity tasks. Compare output quality, task success, latency, and cost per successful task before changing routing rules.

### 2. Department-level spending
**Insight:** Customer Support had the highest total spend, but its share of cost was close to its share of requests.

**Recommendation:** Do not label the department inefficient based on total spend alone. Compare task mix, tokens per request, cost per successful task, and model selection across departments.

### 3. Request reliability
**Insight:** 4.37% of requests were unsuccessful: 2.90% errors and 1.47% timeouts.

**Recommendation:** Investigate error and timeout rates by model, task type, and department. Review timeout thresholds, retry behavior, and whether failed requests still incurred token costs.

### 4. Monthly cost monitoring
**Insight:** Monthly cost varied, with January highest and February lowest.

**Recommendation:** Monitor cost together with request volume and token usage. Investigate unusual changes in cost per request and cost per 1,000 tokens rather than interpreting lower spend as improved efficiency automatically.

### 5. Data quality and reconciliation
**Insight:** Department and request-level token totals match after correcting the department aggregation.

**Recommendation:** Keep reconciliation checks in the recurring analytics workflow. Treat missing token-usage records as data-quality exceptions rather than silently converting them to zero.

## Dashboard structure

The Power BI report is organized into four pages:

1. **Executive Overview** — overall requests, tokens, AI cost, request success rate, and high-level trends.
2. **Cost & Budget** — cost by department, model, and month, with budget comparison where validated.
3. **Model Performance** — model usage, cost, latency, and request status comparison.
4. **Business Value** — task outcomes, estimated time saved, labor value, and ROI where the calculations and filter scope are validated.

## Repository structure

```text
AetherAI/
├── README.md
├── LICENSE
├── .gitignore
├── requirements.txt
├── docs/
│   ├── business_problem_and_objectives.md
│   ├── data_dictionary.md
│   ├── methodology_and_metrics.md
│   ├── insights_and_recommendations.md
│   ├── limitations_and_validation.md
│   └── interview_talking_points.md
├── sql/
│   ├── 01_schema_and_relationships.sql
│   ├── 02_data_quality_checks.sql
│   └── 03_business_analysis_queries.sql
├── python/
│   ├── AetherAI_Python_Analysis.ipynb
│   └── export_outputs.py
├── data/
│   ├── raw/
│   └── processed/
├── powerbi/
│   ├── AetherAI_Dashboard.pbix
│   └── measures_reference.md
└── assets/
    └── dashboard_screenshots/
```

## Reproducibility

1. Create the PostgreSQL schema and load the source data.
2. Run SQL validation checks and analysis queries.
3. Open and run the Python notebook to perform analysis and export processed summaries.
4. Open the Power BI file and refresh its data sources.
5. Review the dashboard and compare its totals against the validated Python outputs.

Add your actual SQL files, notebook, PBIX, and dashboard screenshots to the folders above before publishing the complete repository. Do not upload confidential data or credentials.

## Important validation note

The currently verified Python export contains five CSV outputs: department summary, monthly summary, request-level cost analysis, model summary, and request-status summary. It does not include separate budget-analysis or task-outcome exports. Therefore, budget variance/utilization and estimated labor value/ROI should not be presented as independently validated numeric findings until those outputs are checked against the underlying source data and Power BI measures.

## Author

Add your name, LinkedIn URL, and GitHub profile here.
