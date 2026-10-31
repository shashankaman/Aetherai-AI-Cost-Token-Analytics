# Interview Talking Points

## 30-second project explanation

I built AetherAI, an end-to-end analytics project to understand AI usage, token consumption, model-level API costs, department spending, and request reliability. I used PostgreSQL for relational analysis, Python for data validation and aggregation, and Power BI to present the results across executive, cost, model-performance, and business-value views. The analysis covered 12,000 requests and more than 30.4 million tokens.

## Business problem

Organizations using multiple AI models need visibility into which teams and models drive usage and cost, whether requests complete reliably, and where cost optimization may be possible.

## Technical approach

- Modeled seven related tables in PostgreSQL.
- Used SQL joins and aggregations to analyze request, model, employee, department, and token data.
- Calculated request-level cost using separate input and output token rates.
- Used Python to validate and aggregate outputs.
- Built a four-page Power BI dashboard.

## Strong finding to discuss

Aether-Pro handled 26.05% of requests but contributed 79.59% of total AI cost. I would not immediately recommend replacing it. I would first compare task complexity and output quality, then pilot lower-cost models on suitable tasks with quality and reliability guardrails.

## Data quality example

I identified and corrected a department token aggregation issue. The corrected department totals reconcile with request-level totals at 30,450,854 tokens. This demonstrates why grouped outputs should be reconciled before being used in a dashboard.

## Questions an interviewer may ask

**Why calculate input and output token costs separately?**  
Because the model rate card can price input and output tokens differently.

**Why is the most expensive model not automatically the worst model?**  
Because cost must be evaluated alongside task complexity, output quality, success rate, and latency.

**Why not compare department spend alone?**  
Departments have different request volumes and task mixes. Cost should be normalized using metrics such as cost per request or cost per successful task.

**What is the difference between request success and task success?**  
Request success measures execution status. Task success measures whether the business task achieved its intended outcome.

**What would you improve next?**  
Validate budget and outcome calculations independently, add cost per successful task, analyze failure drivers, and run a model-routing experiment.
