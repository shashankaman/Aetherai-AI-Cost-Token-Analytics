# AetherAI — Complete Power BI DAX Measures Reference

## 1. Data Model & Relationships

The Power BI data model contains the following tables:

- `departments`
- `employees`
- `ai_models`
- `ai_requests`
- `token_usage`
- `task_outcomes`
- `department_budgets`
- `Calendar` (Date Table)

### Recommended relationships

| One side                   | Many side                         |
| -------------------------- | --------------------------------- |
| departments[department_id] | employees[department_id]          |
| employees[employee_id]     | ai_requests[employee_id]          |
| ai_models[model_id]        | ai_requests[model_id]             |
| ai_requests[request_id]    | token_usage[request_id]           |
| ai_requests[request_id]    | task_outcomes[request_id]         |
| departments[department_id] | department_budgets[department_id] |
| Calendar[Date]             | ai_requests[request_date]         |
| Calendar[Date]             | department_budgets[budget_month]  |

Important modeling rules:

- Verify `request_id` uniqueness in `token_usage` and `task_outcomes`.
- Create a date-only column from `ai_requests[request_time]` before relating it to Calendar.
- Use `department_budgets` for monthly budget analysis.
- Do not multiply monthly budgets by joining them to individual request rows.
- Keep request success and business task success separate.

## 2. Core Request Measures

1\. Total Requests

```
Total Requests =
DISTINCTCOUNT(ai_requests[request_id])
```

2\. Successful Requests

```
Successful Requests =
CALCULATE(
    [Total Requests],
    ai_requests[request_status] = "Success"
)
```

3\. Error Requests

```
Error Requests =
CALCULATE(
    [Total Requests],
    ai_requests[request_status] = "Error"
)
```

4\. Timeout Requests

```
Timeout Requests =
CALCULATE(
    [Total Requests],
    ai_requests[request_status] = "Timeout"
)
```

5\. Unsuccessful Requests

```
Unsuccessful Requests =
[Error Requests] + [Timeout Requests]
```

6\. Request Success Rate %

```
Request Success Rate % =
DIVIDE(
    [Successful Requests],
    [Total Requests]
)
```

7\. Request Failure Rate %

```
Request Failure Rate % =
DIVIDE(
    [Unsuccessful Requests],
    [Total Requests]
)
```

## 3. Token Usage Measures

8\. Total Input Tokens

```
Total Input Tokens =
SUM(token_usage[input_tokens])
```

9\. Total Output Tokens

```
Total Output Tokens =
SUM(token_usage[output_tokens])
```

10\. Total Tokens

```
Total Tokens =
[Total Input Tokens] + [Total Output Tokens]
```

11\. Average Tokens per Request

```
Average Tokens per Request =
DIVIDE(
    [Total Tokens],
    [Total Requests]
)
```

12\. Average Input Tokens per Request

```
Average Input Tokens per Request =
DIVIDE(
    [Total Input Tokens],
    [Total Requests]
)
```

13\. Average Output Tokens per Request

```
Average Output Tokens per Request =
DIVIDE(
    [Total Output Tokens],
    [Total Requests]
)
```

## 4. AI Cost Measures

AI model input and output tokens have separate prices per million tokens.

Formula:

\\[ AI\ Cost = \frac{Input\ Tokens \times Input\ Rate + Output\ Tokens \times Output\ Rate}{1,000,000} \\]

14\. Total AI Cost USD

```
Total AI Cost USD =
SUMX(
    token_usage,
    VAR RequestModelID =
        RELATED(ai_requests[model_id])

    VAR InputRate =
        LOOKUPVALUE(
            ai_models[input_rate_per_million_usd],
            ai_models[model_id],
            RequestModelID
        )

    VAR OutputRate =
        LOOKUPVALUE(
            ai_models[output_rate_per_million_usd],
            ai_models[model_id],
            RequestModelID
        )

    RETURN
        DIVIDE(
            token_usage[input_tokens] * InputRate +
            token_usage[output_tokens] * OutputRate,
            1000000
        )
)
```

15\. Average AI Cost per Request USD

```
Average AI Cost per Request USD =
DIVIDE(
    [Total AI Cost USD],
    [Total Requests]
)
```

16\. AI Cost per 1000 Tokens USD

```
AI Cost per 1000 Tokens USD =
DIVIDE(
    [Total AI Cost USD] * 1000,
    [Total Tokens]
)
```

17\. Input Token Cost USD

```
Input Token Cost USD =
SUMX(
    token_usage,
    VAR RequestModelID =
        RELATED(ai_requests[model_id])

    VAR InputRate =
        LOOKUPVALUE(
            ai_models[input_rate_per_million_usd],
            ai_models[model_id],
            RequestModelID
        )

    RETURN
        DIVIDE(
            token_usage[input_tokens] * InputRate,
            1000000
        )
)
```

18\. Output Token Cost USD

```
Output Token Cost USD =
SUMX(
    token_usage,
    VAR RequestModelID =
        RELATED(ai_requests[model_id])

    VAR OutputRate =
        LOOKUPVALUE(
            ai_models[output_rate_per_million_usd],
            ai_models[model_id],
            RequestModelID
        )

    RETURN
        DIVIDE(
            token_usage[output_tokens] * OutputRate,
            1000000
        )
)
```

19\. Input Cost Share %

```
Input Cost Share % =
DIVIDE(
    [Input Token Cost USD],
    [Total AI Cost USD]
)
```

20\. Output Cost Share %

```
Output Cost Share % =
DIVIDE(
    [Output Token Cost USD],
    [Total AI Cost USD]
)
```

## 5. Model Performance Measures

Use `ai_models[model_name]` in your model comparison visuals.

21\. Model Request Count

```
Model Request Count =
[Total Requests]
```

22\. Model Cost USD

```
Model Cost USD =
[Total AI Cost USD]
```

23\. Model Cost Share %

```
Model Cost Share % =
DIVIDE(
    [Model Cost USD],
    CALCULATE(
        [Total AI Cost USD],
        REMOVEFILTERS(ai_models[model_name])
    )
)
```

24\. Model Average Cost per Request USD

```
Model Average Cost per Request USD =
DIVIDE(
    [Model Cost USD],
    [Model Request Count]
)
```

25\. Average Latency ms

```
Average Latency ms =
AVERAGE(ai_requests[latency_ms])
```

26\. Median Latency ms

```
Median Latency ms =
MEDIAN(ai_requests[latency_ms])
```

27\. P95 Latency ms

```
P95 Latency ms =
PERCENTILEX.INC(
    FILTER(
        ai_requests,
        NOT ISBLANK(ai_requests[latency_ms])
    ),
    ai_requests[latency_ms],
    0.95
)
```

## 6. Department Analysis Measures

Use `departments[department_name]` in department visuals.

28\. Department Request Count

```
Department Request Count =
[Total Requests]
```

29\. Department AI Cost USD

```
Department AI Cost USD =
[Total AI Cost USD]
```

30\. Department Cost Share %

```
Department Cost Share % =
DIVIDE(
    [Department AI Cost USD],
    CALCULATE(
        [Total AI Cost USD],
        REMOVEFILTERS(departments[department_name])
    )
)
```

31\. Department Request Share %

```
Department Request Share % =
DIVIDE(
    [Department Request Count],
    CALCULATE(
        [Total Requests],
        REMOVEFILTERS(departments[department_name])
    )
)
```

32\. Department Average Cost per Request USD

```
Department Average Cost per Request USD =
DIVIDE(
    [Department AI Cost USD],
    [Department Request Count]
)
```

## 7. Budget Analysis Measures

Use `department_budgets[budget_amount_usd]` for monthly budgets.

33\. Monthly Budget USD

```
Monthly Budget USD =
SUM(department_budgets[budget_amount_usd])
```

34\. Actual Spend USD

```
Actual Spend USD =
[Total AI Cost USD]
```

35\. Budget Variance USD

```
Budget Variance USD =
[Actual Spend USD] - [Monthly Budget USD]
```

36\. Budget Utilization %

```
Budget Utilization % =
DIVIDE(
    [Actual Spend USD],
    [Monthly Budget USD]
)
```

37\. Remaining Budget USD

```
Remaining Budget USD =
[Monthly Budget USD] - [Actual Spend USD]
```

Interpretation:

- Positive Budget Variance = Over Budget.
- Negative Budget Variance = Under Budget.
- Budget Utilization above 100% = Budget exceeded.
- Remaining Budget positive = Budget still available.

Important: Actual spend and budget must have the same department and month filters. Verify the relationships before using these measures.

## 8. Business Value & Task Outcome Measures

`task_outcomes[task_successful]` measures business task success. It is not the same as `ai_requests[request_status]`.

38\. Successful Tasks

```
Successful Tasks =
CALCULATE(
    DISTINCTCOUNT(task_outcomes[request_id]),
    task_outcomes[task_successful] = TRUE()
)
```

39\. Total Tasks with Outcome

```
Total Tasks with Outcome =
DISTINCTCOUNT(task_outcomes[request_id])
```

40\. Task Success Rate %

```
Task Success Rate % =
DIVIDE(
    [Successful Tasks],
    [Total Tasks with Outcome]
)
```

41\. Total Time Saved Minutes

```
Total Time Saved Minutes =
SUM(task_outcomes[time_saved_minutes])
```

42\. Total Time Saved Hours

```
Total Time Saved Hours =
DIVIDE(
    [Total Time Saved Minutes],
    60
)
```

43\. Estimated Labor Value USD

```
Estimated Labor Value USD =
SUMX(
    task_outcomes,
    DIVIDE(
        task_outcomes[time_saved_minutes] *
        task_outcomes[hourly_labor_cost_usd],
        60
    )
)
```

44\. Estimated Net Value USD

```
Estimated Net Value USD =
[Estimated Labor Value USD] - [Total AI Cost USD]
```

45\. Estimated ROI %

```
Estimated ROI % =
DIVIDE(
    [Estimated Labor Value USD] - [Total AI Cost USD],
    [Total AI Cost USD]
)
```

ROI interpretation:

- Positive ROI = Estimated labor value is higher than AI cost.
- Negative ROI = Estimated labor value is lower than AI cost.
- ROI is blank when AI cost is zero.
- Labor value is an estimate, not necessarily realized cash savings.
- Both labor value and AI cost must use the same date range, request population, and filter context.
- Independently validate ROI before publishing it as a final business result.

## 9. Monthly Trend Measures

These measures assume a continuous Calendar table named `Calendar`, with `Calendar[Date]` related to the date-only request date.

46\. Previous Month AI Cost USD

```
Previous Month AI Cost USD =
CALCULATE(
    [Total AI Cost USD],
    DATEADD(Calendar[Date], -1, MONTH)
)
```

47\. Month-over-Month Cost Change USD

```
Month-over-Month Cost Change USD =
[Total AI Cost USD] - [Previous Month AI Cost USD]
```

48\. Month-over-Month Cost Change %

```
Month-over-Month Cost Change % =
DIVIDE(
    [Month-over-Month Cost Change USD],
    [Previous Month AI Cost USD]
)
```

49\. Previous Month Requests

```
Previous Month Requests =
CALCULATE(
    [Total Requests],
    DATEADD(Calendar[Date], -1, MONTH)
)
```

50\. Month-over-Month Request Change %

```
Month-over-Month Request Change % =
DIVIDE(
    [Total Requests] - [Previous Month Requests],
    [Previous Month Requests]
)
```

## 10. Dashboard Page-wise Measure Mapping

| Dashboard Page     | Recommended Measures                                                                                                                               |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Executive Overview | Total Requests, Total Tokens, Total AI Cost USD, Request Success Rate %, monthly cost trend                                                        |
| Cost & Budget      | Total AI Cost USD, Department AI Cost USD, Monthly Budget USD, Actual Spend USD, Budget Variance USD, Budget Utilization %, Remaining Budget USD   |
| Model Performance  | Model Request Count, Model Cost USD, Model Cost Share %, Model Average Cost per Request USD, Average Latency ms, Median Latency ms, P95 Latency ms |
| Business Value     | Successful Tasks, Task Success Rate %, Total Time Saved Hours, Estimated Labor Value USD, Estimated Net Value USD, Estimated ROI %                 |

## 11. Measure Formatting Guide

| Measure Type       | Recommended Format                    |
| ------------------ | ------------------------------------- |
| Request Counts     | Whole Number                          |
| Token Counts       | Whole Number with Thousands Separator |
| AI Cost            | Currency — USD                        |
| Budget             | Currency — USD                        |
| Labor Value        | Currency — USD                        |
| Success Rate       | Percentage                            |
| Failure Rate       | Percentage                            |
| Budget Utilization | Percentage                            |
| ROI                | Percentage                            |
| Latency            | Milliseconds                          |
| Time Saved         | Hours                                 |

Important: Percentage measures should return decimal ratios and be formatted as Percentage in Power BI. Do not multiply by 100 inside the DAX measure.

## 12. Final Validation Checklist

- `ai_requests[request_id]` is unique.
- `token_usage[request_id]` is unique if using one-to-one relationships.
- `task_outcomes[request_id]` is unique if using one-to-one relationships.
- Each request maps to exactly one AI model.
- Model input/output rates are populated.
- Input token total matches Python output.
- Output token total matches Python output.
- Total tokens match Python output.
- Total AI cost reconciles across request, model, department, and month summaries.
- Request status counts reconcile to total requests.
- Budget is aggregated at department-month grain.
- Labor value and AI cost use matching reporting periods and populations.
- ROI is blank when AI cost is zero.
- ROI has been independently validated before publication.
- Percentage measures are formatted correctly.

Project: AetherAI — AI Cost & Token Usage Analytics

Tools: PostgreSQL | Python | Power BI

Purpose: AI Usage Analytics, Token Consumption, Cost Monitoring, Model Performance, Department Analysis, and Business Value Assessment.

## 13. Important note before using these measures

These are the complete reference measures for the project, but they are not all automatically validated in your current report. In particular:

- Check the `RELATED(ai_requests[model_id])` relationship used by the cost measures.
- Confirm Calendar filters reach both actual cost and monthly budgets correctly.
- Confirm task outcomes are filtered consistently with AI requests.
- Verify budget and ROI cards against independent SQL/Python calculations.

Do not treat the presence of a DAX formula in this document as proof that its displayed result is correct.\
"""