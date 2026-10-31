# Key Insights & Business Recommendations

## Insight 1 — AI cost is concentrated in Aether-Pro

**Evidence**
- Aether-Pro handled 3,126 requests (26.05%).
- Its cost was approximately $30.17 (79.59% of total cost).
- Average cost per request was approximately $0.009651, versus $0.000965 for Aether-Flash.

**Interpretation**
Aether-Pro is substantially more expensive per request in this dataset. This does not prove it is inefficient: task complexity and output quality have not been compared here.

**Recommendation**
Run a controlled model-routing pilot. Identify lower-complexity task types and test whether Aether-Flash or OpenLite can handle them while meeting quality, success-rate, and latency thresholds.

**Success measures**
- Cost per successful task
- Task success / quality score
- Request success rate
- Median and p95 latency
- Cost savings versus baseline

## Insight 2 — Customer Support is the largest department by spend and volume

**Evidence**
- 3,395 requests (28.29% of requests).
- Approximately $10.65 cost (28.09% of cost).

**Interpretation**
Its share of cost is close to its share of requests. Total spend alone is not evidence of overspending.

**Recommendation**
Compare task mix, average tokens per request, model mix, and cost per successful task across departments. Investigate only after normalizing for workload and task complexity.

## Insight 3 — Request reliability needs investigation

**Evidence**
- 11,476 successful requests (95.63%).
- 348 errors (2.90%).
- 176 timeouts (1.47%).
- Total unsuccessful requests: 524 (4.37%).

**Recommendation**
Segment failures by model, task type, and department. Review error categories, timeout settings, retry logic, and whether failed requests consume billable tokens.

**Success measures**
- Error rate
- Timeout rate
- Retry rate
- Cost of unsuccessful requests
- Successful task rate

## Insight 4 — Monthly AI cost fluctuates

**Evidence**
- January: approximately $3.56 (highest).
- February: approximately $2.83 (lowest).
- December was approximately 10.48% below January.

**Interpretation**
The series does not show a consistent upward trend. Lower cost alone does not prove improved efficiency because workload and outcomes must also be considered.

**Recommendation**
Track cost alongside request volume, tokens, cost per request, and cost per successful task. Investigate unusual month-to-month changes.

## Insight 5 — Token aggregation reconciles after correction

**Evidence**
- Input tokens: 21,235,456.
- Output tokens: 9,215,398.
- Total tokens: 30,450,854.
- Department-level totals match request-level totals.

**Recommendation**
Keep reconciliation checks in the pipeline and fail or flag the export if grouped totals do not match request-level totals.

## Not yet independently validated

The verified export package does not contain separate budget-analysis or task-outcome exports. Do not publish numerical budget variance, budget utilization, estimated labor value, or estimated ROI as validated conclusions until the underlying calculations and filters have been reconciled.
