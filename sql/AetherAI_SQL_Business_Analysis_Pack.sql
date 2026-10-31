-- AetherAI — AI Cost & Token Analytics
-- PostgreSQL / pgAdmin SQL business analysis pack
-- Dataset is synthetic. Run after importing the seven CSV tables.
-- Expected tables:
-- departments(department_id, department_name, monthly_budget_usd)
-- employees(employee_id, employee_name, department_id, role)
-- ai_models(model_id, provider, model_name, input_rate_per_million_usd, output_rate_per_million_usd, model_tier)
-- ai_requests(request_id, employee_id, model_id, request_time, task_type, request_status, latency_ms)
-- token_usage(request_id, input_tokens, output_tokens)
-- task_outcomes(request_id, task_type, task_successful, time_saved_minutes, hourly_labor_cost_usd)
-- department_budgets(department_id, budget_month, budget_amount_usd)

-- IMPORTANT:
-- 1) Review column names/types in your actual imported tables first.
-- 2) Cost = (input_tokens * input_rate + output_tokens * output_rate) / 1,000,000.
-- 3) task_outcomes.task_successful is the success measure; do not infer success from request_status.
-- 4) Estimated labor value is an estimate, not guaranteed cash savings.
-- 5) Use numeric casts for accurate decimal output.

-- 00. Table row counts
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'employees', COUNT(*) FROM employees
UNION ALL SELECT 'ai_models', COUNT(*) FROM ai_models
UNION ALL SELECT 'ai_requests', COUNT(*) FROM ai_requests
UNION ALL SELECT 'token_usage', COUNT(*) FROM token_usage
UNION ALL SELECT 'task_outcomes', COUNT(*) FROM task_outcomes
UNION ALL SELECT 'department_budgets', COUNT(*) FROM department_budgets
ORDER BY table_name;

-- 01. Overall usage and date range
SELECT COUNT(*) AS total_requests,
       COUNT(DISTINCT employee_id) AS unique_employees,
       COUNT(DISTINCT model_id) AS models_used,
       MIN(request_time) AS first_request,
       MAX(request_time) AS last_request
FROM ai_requests;

-- 02. Monthly request volume
SELECT DATE_TRUNC('month', request_time)::date AS month,
       COUNT(*) AS total_requests
FROM ai_requests
GROUP BY 1 ORDER BY 1;

-- 03. Task mix and percentage of all requests
SELECT task_type, COUNT(*) AS requests,
       ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS request_share_pct
FROM ai_requests
GROUP BY task_type
ORDER BY requests DESC;

-- 04. Request status distribution
SELECT request_status, COUNT(*) AS requests,
       ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS share_pct
FROM ai_requests
GROUP BY request_status
ORDER BY requests DESC;

-- 05. Department adoption
SELECT d.department_name, COUNT(DISTINCT e.employee_id) AS employees,
       COUNT(r.request_id) AS requests,
       COUNT(DISTINCT r.employee_id) AS active_employees
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id
LEFT JOIN ai_requests r ON r.employee_id = e.employee_id
GROUP BY d.department_id, d.department_name
ORDER BY requests DESC;

-- 06. Employees with most requests
SELECT e.employee_id, e.employee_name, d.department_name, e.role,
       COUNT(r.request_id) AS requests
FROM employees e
LEFT JOIN departments d ON d.department_id = e.department_id
LEFT JOIN ai_requests r ON r.employee_id = e.employee_id
GROUP BY e.employee_id, e.employee_name, d.department_name, e.role
ORDER BY requests DESC
LIMIT 20;

-- 07. Total token usage
SELECT SUM(input_tokens) AS total_input_tokens,
       SUM(output_tokens) AS total_output_tokens,
       SUM(COALESCE(input_tokens,0) + COALESCE(output_tokens,0)) AS total_tokens
FROM token_usage;

-- 08. Token use by model
SELECT m.provider, m.model_name, m.model_tier,
       SUM(COALESCE(t.input_tokens,0)) AS input_tokens,
       SUM(COALESCE(t.output_tokens,0)) AS output_tokens,
       SUM(COALESCE(t.input_tokens,0) + COALESCE(t.output_tokens,0)) AS total_tokens,
       COUNT(DISTINCT r.request_id) AS requests
FROM ai_requests r
JOIN ai_models m ON m.model_id = r.model_id
LEFT JOIN token_usage t ON t.request_id = r.request_id
GROUP BY m.provider, m.model_name, m.model_tier
ORDER BY total_tokens DESC;

-- 09. Token usage by department
SELECT d.department_name,
       SUM(COALESCE(t.input_tokens,0)) AS input_tokens,
       SUM(COALESCE(t.output_tokens,0)) AS output_tokens,
       SUM(COALESCE(t.input_tokens,0) + COALESCE(t.output_tokens,0)) AS total_tokens
FROM ai_requests r
JOIN employees e ON e.employee_id = r.employee_id
JOIN departments d ON d.department_id = e.department_id
LEFT JOIN token_usage t ON t.request_id = r.request_id
GROUP BY d.department_name
ORDER BY total_tokens DESC;

-- Reusable cost logic (repeat CTE in cost queries):
-- request_cost = ((input_tokens * input_rate_per_million_usd)
--               + (output_tokens * output_rate_per_million_usd)) / 1000000.0

-- 10. Total AI cost and cost coverage
WITH request_costs AS (
  SELECT r.request_id,
         (COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0 AS ai_cost_usd
  FROM ai_requests r
  JOIN ai_models m ON m.model_id = r.model_id
  LEFT JOIN token_usage t ON t.request_id = r.request_id
)
SELECT COUNT(*) AS requests_costed,
       ROUND(SUM(ai_cost_usd)::numeric, 4) AS total_ai_cost_usd,
       ROUND(AVG(ai_cost_usd)::numeric, 6) AS avg_cost_per_request_usd
FROM request_costs;

-- 11. Cost by model
WITH request_costs AS (
  SELECT r.request_id, m.provider, m.model_name, m.model_tier,
         (COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0 AS ai_cost_usd
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
)
SELECT provider, model_name, model_tier, COUNT(*) AS requests,
       ROUND(SUM(ai_cost_usd)::numeric,4) AS total_cost_usd,
       ROUND(AVG(ai_cost_usd)::numeric,6) AS avg_cost_per_request_usd
FROM request_costs
GROUP BY provider, model_name, model_tier
ORDER BY total_cost_usd DESC;

-- 12. Cost by department
WITH request_costs AS (
  SELECT r.request_id, e.department_id,
         (COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0 AS ai_cost_usd
  FROM ai_requests r
  JOIN employees e ON e.employee_id=r.employee_id
  JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
)
SELECT d.department_name, COUNT(*) AS requests,
       ROUND(SUM(rc.ai_cost_usd)::numeric,4) AS total_cost_usd
FROM request_costs rc JOIN departments d ON d.department_id=rc.department_id
GROUP BY d.department_name ORDER BY total_cost_usd DESC;

-- 13. Monthly AI cost trend
WITH request_costs AS (
  SELECT DATE_TRUNC('month', r.request_time)::date AS month,
         (COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0 AS ai_cost_usd
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
)
SELECT month, COUNT(*) AS requests,
       ROUND(SUM(ai_cost_usd)::numeric,4) AS total_cost_usd
FROM request_costs GROUP BY month ORDER BY month;

-- 14. Cost by task type
WITH request_costs AS (
  SELECT r.task_type,
         (COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0 AS ai_cost_usd
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
)
SELECT task_type, COUNT(*) AS requests,
       ROUND(SUM(ai_cost_usd)::numeric,4) AS total_cost_usd,
       ROUND(AVG(ai_cost_usd)::numeric,6) AS avg_cost_per_request_usd
FROM request_costs GROUP BY task_type ORDER BY total_cost_usd DESC;

-- 15. Top 25 most expensive individual requests
SELECT r.request_id, r.request_time, r.task_type, e.employee_name,
       d.department_name, m.model_name,
       COALESCE(t.input_tokens,0) AS input_tokens,
       COALESCE(t.output_tokens,0) AS output_tokens,
       ROUND(((COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0)::numeric,6) AS ai_cost_usd
FROM ai_requests r
JOIN employees e ON e.employee_id=r.employee_id
JOIN departments d ON d.department_id=e.department_id
JOIN ai_models m ON m.model_id=r.model_id
LEFT JOIN token_usage t ON t.request_id=r.request_id
ORDER BY ai_cost_usd DESC LIMIT 25;

-- 16. Monthly department spend vs budget; aggregate spend to department-month before joining
WITH spend AS (
  SELECT e.department_id, DATE_TRUNC('month',r.request_time)::date AS budget_month,
         SUM((COALESCE(t.input_tokens,0) * m.input_rate_per_million_usd
             + COALESCE(t.output_tokens,0) * m.output_rate_per_million_usd) / 1000000.0) AS actual_spend_usd
  FROM ai_requests r
  JOIN employees e ON e.employee_id=r.employee_id
  JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
  GROUP BY e.department_id, DATE_TRUNC('month',r.request_time)::date
),
budgets AS (
  SELECT department_id, DATE_TRUNC('month',budget_month)::date AS budget_month,
         SUM(budget_amount_usd) AS budget_usd
  FROM department_budgets
  GROUP BY department_id, DATE_TRUNC('month',budget_month)::date
)
SELECT d.department_name, COALESCE(s.budget_month,b.budget_month) AS month,
       ROUND(COALESCE(s.actual_spend_usd,0)::numeric,4) AS actual_spend_usd,
       ROUND(COALESCE(b.budget_usd,0)::numeric,4) AS budget_usd,
       ROUND((COALESCE(s.actual_spend_usd,0)-COALESCE(b.budget_usd,0))::numeric,4) AS variance_usd,
       CASE WHEN COALESCE(b.budget_usd,0)=0 THEN NULL
            ELSE ROUND((100.0*s.actual_spend_usd/b.budget_usd)::numeric,2) END AS budget_used_pct,
       CASE WHEN COALESCE(s.actual_spend_usd,0)>COALESCE(b.budget_usd,0) THEN 'Over budget'
            WHEN COALESCE(b.budget_usd,0)=0 THEN 'No budget record'
            ELSE 'Within budget' END AS budget_status
FROM spend s
FULL OUTER JOIN budgets b
  ON b.department_id=s.department_id AND b.budget_month=s.budget_month
JOIN departments d ON d.department_id=COALESCE(s.department_id,b.department_id)
ORDER BY month, d.department_name;

-- 17. Over-budget department-months (same grain, complete query)
WITH spend AS (
  SELECT e.department_id, DATE_TRUNC('month',r.request_time)::date AS month,
         SUM((COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
             + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0) AS actual_spend
  FROM ai_requests r JOIN employees e ON e.employee_id=r.employee_id
  JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
  GROUP BY e.department_id, DATE_TRUNC('month',r.request_time)::date
),
budgets AS (
  SELECT department_id, DATE_TRUNC('month',budget_month)::date AS month,
         SUM(budget_amount_usd) AS budget
  FROM department_budgets
  GROUP BY department_id, DATE_TRUNC('month',budget_month)::date
)
SELECT d.department_name, s.month, ROUND(s.actual_spend::numeric,4) AS actual_spend_usd,
       ROUND(b.budget::numeric,4) AS budget_usd,
       ROUND((s.actual_spend-b.budget)::numeric,4) AS over_budget_usd
FROM spend s JOIN budgets b USING(department_id,month)
JOIN departments d ON d.department_id=s.department_id
WHERE s.actual_spend>b.budget
ORDER BY over_budget_usd DESC;

-- 18. Latency by model (milliseconds)
SELECT m.provider, m.model_name, COUNT(r.request_id) AS requests,
       ROUND(AVG(r.latency_ms)::numeric,2) AS avg_latency_ms,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY r.latency_ms) AS median_latency_ms,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY r.latency_ms) AS p95_latency_ms
FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
WHERE r.latency_ms IS NOT NULL
GROUP BY m.provider,m.model_name ORDER BY avg_latency_ms DESC;

-- 19. Task success rate by task type
SELECT task_type, COUNT(*) AS outcome_records,
       COUNT(*) FILTER (WHERE task_successful IS TRUE) AS successful_tasks,
       ROUND(100.0*COUNT(*) FILTER (WHERE task_successful IS TRUE)/NULLIF(COUNT(*),0),2) AS success_rate_pct
FROM task_outcomes
GROUP BY task_type ORDER BY success_rate_pct DESC;

-- 20. AI cost per successful task, cost attributed to successful requests only
WITH outcomes AS (
  SELECT request_id, BOOL_OR(task_successful IS TRUE) AS successful,
         MAX(time_saved_minutes) AS time_saved_minutes,
         MAX(hourly_labor_cost_usd) AS hourly_labor_cost_usd
  FROM task_outcomes GROUP BY request_id
),
costs AS (
  SELECT r.request_id,
         (COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0 AS ai_cost_usd
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
)
SELECT COUNT(*) FILTER (WHERE o.successful) AS successful_requests,
       ROUND(SUM(c.ai_cost_usd) FILTER (WHERE o.successful)::numeric,4) AS cost_of_successful_requests_usd,
       ROUND((SUM(c.ai_cost_usd) FILTER (WHERE o.successful)
         / NULLIF(COUNT(*) FILTER (WHERE o.successful),0))::numeric,6) AS cost_per_successful_request_usd,
       ROUND((SUM(c.ai_cost_usd)/NULLIF(COUNT(*) FILTER (WHERE o.successful),0))::numeric,6)
         AS total_ai_cost_per_successful_request_including_failed_costs
FROM costs c JOIN outcomes o ON o.request_id=c.request_id;

-- 21. Time saved by task type and overall
SELECT task_type, COUNT(*) AS outcome_records,
       SUM(COALESCE(time_saved_minutes,0)) AS total_time_saved_minutes,
       ROUND((SUM(COALESCE(time_saved_minutes,0))/60.0)::numeric,2) AS total_time_saved_hours,
       ROUND(AVG(time_saved_minutes)::numeric,2) AS avg_minutes_saved_per_task
FROM task_outcomes
GROUP BY task_type ORDER BY total_time_saved_minutes DESC;

-- 22. Estimated labor value of time saved (not necessarily cash savings)
SELECT task_type,
       ROUND(SUM(COALESCE(time_saved_minutes,0)*COALESCE(hourly_labor_cost_usd,0)/60.0)::numeric,2)
         AS estimated_labor_value_usd
FROM task_outcomes
GROUP BY task_type ORDER BY estimated_labor_value_usd DESC;

-- 23. Estimated ROI by month (estimated labor value minus AI cost) / AI cost
WITH outcome_per_request AS (
  SELECT request_id, MAX(time_saved_minutes) AS time_saved_minutes,
         MAX(hourly_labor_cost_usd) AS hourly_labor_cost_usd
  FROM task_outcomes GROUP BY request_id
),
monthly_cost AS (
  SELECT DATE_TRUNC('month',r.request_time)::date AS month,
         SUM((COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
             + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0) AS ai_cost
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
  GROUP BY 1
),
monthly_value AS (
  SELECT DATE_TRUNC('month',r.request_time)::date AS month,
         SUM(COALESCE(o.time_saved_minutes,0)*COALESCE(o.hourly_labor_cost_usd,0)/60.0) AS labor_value
  FROM ai_requests r JOIN outcome_per_request o ON o.request_id=r.request_id
  GROUP BY 1
)
SELECT c.month, ROUND(c.ai_cost::numeric,2) AS ai_cost_usd,
       ROUND(COALESCE(v.labor_value,0)::numeric,2) AS estimated_labor_value_usd,
       ROUND((COALESCE(v.labor_value,0)-c.ai_cost)::numeric,2) AS estimated_net_value_usd,
       ROUND((100.0*(COALESCE(v.labor_value,0)-c.ai_cost)/NULLIF(c.ai_cost,0))::numeric,2)
         AS estimated_roi_pct
FROM monthly_cost c LEFT JOIN monthly_value v USING(month)
ORDER BY c.month;

-- 24. Month-over-month AI cost change
WITH monthly_cost AS (
  SELECT DATE_TRUNC('month',r.request_time)::date AS month,
         SUM((COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
             + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0) AS cost
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
  GROUP BY 1
)
SELECT month, ROUND(cost::numeric,4) AS cost_usd,
       ROUND((cost-LAG(cost) OVER(ORDER BY month))::numeric,4) AS mom_change_usd,
       ROUND((100.0*(cost-LAG(cost) OVER(ORDER BY month))
          / NULLIF(LAG(cost) OVER(ORDER BY month),0))::numeric,2) AS mom_change_pct
FROM monthly_cost ORDER BY month;

-- 25. Department share of total AI cost
WITH dept_cost AS (
  SELECT d.department_id,d.department_name,
         SUM((COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
             + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0) AS cost
  FROM ai_requests r JOIN employees e ON e.employee_id=r.employee_id
  JOIN departments d ON d.department_id=e.department_id
  JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
  GROUP BY d.department_id,d.department_name
)
SELECT department_name, ROUND(cost::numeric,4) AS cost_usd,
       ROUND(100.0*cost/NULLIF(SUM(cost) OVER(),0),2) AS share_of_total_cost_pct
FROM dept_cost ORDER BY cost DESC;

-- 26. High-cost requests: above the 95th percentile request cost
WITH costs AS (
  SELECT r.request_id,r.request_time,r.task_type,m.model_name,
         (COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
          + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0 AS cost
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
),
threshold AS (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY cost) AS p95_cost FROM costs)
SELECT c.*, ROUND(th.p95_cost::numeric,6) AS p95_threshold_usd
FROM costs c CROSS JOIN threshold th
WHERE c.cost>=th.p95_cost ORDER BY c.cost DESC;

-- 27. Duplicate primary IDs in core tables (each query should return zero rows)
SELECT request_id, COUNT(*) FROM ai_requests GROUP BY request_id HAVING COUNT(*)>1;
SELECT employee_id, COUNT(*) FROM employees GROUP BY employee_id HAVING COUNT(*)>1;
SELECT model_id, COUNT(*) FROM ai_models GROUP BY model_id HAVING COUNT(*)>1;

-- 28. Requests missing token usage
SELECT r.request_id, r.request_time, r.task_type
FROM ai_requests r LEFT JOIN token_usage t ON t.request_id=r.request_id
WHERE t.request_id IS NULL ORDER BY r.request_time;

-- 29. Token usage rows with no matching request
SELECT t.request_id
FROM token_usage t LEFT JOIN ai_requests r ON r.request_id=t.request_id
WHERE r.request_id IS NULL;

-- 30. Negative or null token values
SELECT * FROM token_usage
WHERE input_tokens IS NULL OR output_tokens IS NULL
   OR input_tokens<0 OR output_tokens<0;

-- 31. Requests missing employee/model foreign keys
SELECT r.request_id
FROM ai_requests r LEFT JOIN employees e ON e.employee_id=r.employee_id
LEFT JOIN ai_models m ON m.model_id=r.model_id
WHERE e.employee_id IS NULL OR m.model_id IS NULL;

-- 32. Outcome rows with no matching request
SELECT o.request_id
FROM task_outcomes o LEFT JOIN ai_requests r ON r.request_id=o.request_id
WHERE r.request_id IS NULL;

-- 33. Duplicate token_usage rows per request (should normally be zero)
SELECT request_id, COUNT(*) AS rows_per_request
FROM token_usage GROUP BY request_id HAVING COUNT(*)>1;

-- 34. Duplicate task_outcomes rows per request (inspect expected grain)
SELECT request_id, COUNT(*) AS rows_per_request
FROM task_outcomes GROUP BY request_id HAVING COUNT(*)>1;

-- 35. Missing/invalid model rates
SELECT *
FROM ai_models
WHERE input_rate_per_million_usd IS NULL
   OR output_rate_per_million_usd IS NULL
   OR input_rate_per_million_usd<0
   OR output_rate_per_million_usd<0;

-- 36. Invalid latency values
SELECT request_id, latency_ms
FROM ai_requests
WHERE latency_ms IS NULL OR latency_ms<0;

-- 37. Request status/task outcome cross-check (inspect; don't assume same meaning)
SELECT r.request_status, o.task_successful, COUNT(*) AS records
FROM ai_requests r LEFT JOIN task_outcomes o ON o.request_id=r.request_id
GROUP BY r.request_status,o.task_successful
ORDER BY r.request_status,o.task_successful;

-- 38. Department budget duplicates at department-month grain
SELECT department_id, DATE_TRUNC('month',budget_month)::date AS month,
       COUNT(*) AS rows_at_grain, SUM(budget_amount_usd) AS summed_budget
FROM department_budgets
GROUP BY department_id, DATE_TRUNC('month',budget_month)::date
HAVING COUNT(*)>1;

-- 39. Quick KPI summary for Power BI validation
WITH cost AS (
  SELECT COUNT(*) AS requests,
         SUM((COALESCE(t.input_tokens,0)*m.input_rate_per_million_usd
             + COALESCE(t.output_tokens,0)*m.output_rate_per_million_usd)/1000000.0) AS ai_cost
  FROM ai_requests r JOIN ai_models m ON m.model_id=r.model_id
  LEFT JOIN token_usage t ON t.request_id=r.request_id
),
tokens AS (
  SELECT SUM(COALESCE(input_tokens,0)+COALESCE(output_tokens,0)) AS total_tokens
  FROM token_usage
),
outcomes AS (
  SELECT COUNT(*) AS outcome_count,
         COUNT(*) FILTER(WHERE task_successful IS TRUE) AS successful_tasks,
         SUM(COALESCE(time_saved_minutes,0)) AS time_saved_minutes
  FROM task_outcomes
)
SELECT cost.requests, ROUND(cost.ai_cost::numeric,4) AS total_ai_cost_usd,
       tokens.total_tokens, outcomes.successful_tasks,
       ROUND(100.0*outcomes.successful_tasks/NULLIF(outcomes.outcome_count,0),2) AS success_rate_pct,
       ROUND((outcomes.time_saved_minutes/60.0)::numeric,2) AS time_saved_hours
FROM cost CROSS JOIN tokens CROSS JOIN outcomes;

-- END OF PACK
