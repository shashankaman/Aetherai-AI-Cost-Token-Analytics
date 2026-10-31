-- AetherAI Token Analytics PostgreSQL schema
-- Create/use a separate database named aetherai_token_analytics before running this script.

CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    monthly_budget_usd NUMERIC(12,2) NOT NULL
);

CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department_id INTEGER NOT NULL REFERENCES departments(department_id),
    role VARCHAR(50)
);

CREATE TABLE ai_models (
    model_id INTEGER PRIMARY KEY,
    provider VARCHAR(100),
    model_name VARCHAR(100) NOT NULL,
    input_rate_per_million_usd NUMERIC(12,4) NOT NULL,
    output_rate_per_million_usd NUMERIC(12,4) NOT NULL,
    model_tier VARCHAR(50)
);

CREATE TABLE ai_requests (
    request_id BIGINT PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    model_id INTEGER NOT NULL REFERENCES ai_models(model_id),
    request_time TIMESTAMP NOT NULL,
    task_type VARCHAR(50),
    request_status VARCHAR(20),
    latency_ms INTEGER
);

CREATE TABLE token_usage (
    request_id BIGINT PRIMARY KEY REFERENCES ai_requests(request_id),
    input_tokens INTEGER NOT NULL,
    output_tokens INTEGER NOT NULL
);

CREATE TABLE task_outcomes (
    request_id BIGINT PRIMARY KEY REFERENCES ai_requests(request_id),
    task_type VARCHAR(50),
    task_successful BOOLEAN,
    time_saved_minutes INTEGER,
    hourly_labor_cost_usd NUMERIC(8,2)
);

CREATE TABLE department_budgets (
    department_id INTEGER NOT NULL REFERENCES departments(department_id),
    budget_month DATE NOT NULL,
    budget_amount_usd NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (department_id, budget_month)
);
