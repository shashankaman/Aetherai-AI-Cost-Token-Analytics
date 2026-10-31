# Limitations, Assumptions & Validation Status

## Verified in the latest Python export

- Five expected CSV outputs are present: department summary, monthly summary, request-level cost analysis, model summary, and request-status summary.
- Request-level analysis contains 12,000 rows and 12,000 unique request IDs.
- Request-level token totals: 21,235,456 input; 9,215,398 output; 30,450,854 combined.
- Department-level token totals reconcile to request-level totals.
- Model, department, month, and request-status summaries reconcile for the verified totals.

## Not independently verified from the current export

The latest export does not include separate budget-analysis or task-outcome outputs. Therefore:
- Budget variance and budget utilization need source-level validation.
- Estimated labor value and estimated ROI need source-level validation.
- Power BI cards for these metrics should be checked against independently calculated results.

## Interpretation limitations

- Model cost and latency do not establish model quality or efficiency.
- Department total spend should be normalized by workload and task mix.
- Estimated labor value is not necessarily cash savings.
- Request execution success is not the same as business task success.
- Failed requests may still incur cost; this needs request-level validation.
- Monthly cost changes should be interpreted with request volume and token usage.

## Before publishing

- Add the actual SQL scripts, latest Python notebook, PBIX, and dashboard screenshots.
- Remove credentials, personal data, and confidential source data.
- Confirm README metrics match the final exported data.
- Reconcile Power BI totals with Python outputs.
- Validate budget and outcome measures before presenting them as final.
