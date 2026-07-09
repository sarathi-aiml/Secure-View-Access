-- =============================================================================
-- Cortex AI Usage Intelligence - Agent
-- Creates a Cortex Agent with semantic view tools + chart generation
-- Run as: ACCOUNTADMIN (after 01, 02, 03 scripts)
-- =============================================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE AGENT PUBLIC_METADATA.AI.AI_USAGE_AGENT
COMMENT = 'AI Usage Intelligence - Natural language queries over all Cortex AI token and credit consumption'
FROM SPECIFICATION
$$
models:
  orchestration: "claude-sonnet-4-5"
instructions:
  response: "Present data clearly with formatted numbers. When showing trends or comparisons, always generate a chart. Format credits to 2 decimal places. Format tokens with comma separators. If no time range specified, default to last 30 days."
  orchestration: "You are an AI Usage Intelligence assistant for DBAs and platform teams. Route queries as follows: (1) Cross-product questions (total usage, top users, product comparison, daily trends) -> query_all_usage. (2) Cortex Code specific (CLI vs Snowsight, Code user breakdown) -> query_code_usage. (3) Agent specific (which agent costs most, agent by user) -> query_agent_usage. (4) Always generate a chart for trends and comparisons using chart_generation tool."
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "query_all_usage"
      description: "Query unified Cortex AI usage across ALL products (Code CLI, Snowsight, Desktop, Agents, AI Functions, Analyst, AI SQL, Guard, Search, REST API, Document AI, Fine-Tuning). Use for cross-product comparisons, top users, daily/weekly trends, role breakdown."
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "query_code_usage"
      description: "Query Cortex Code usage specifically. Drill into CLI vs Snowsight vs Desktop, by user, model, role. Use when question is specifically about Cortex Code."
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "query_agent_usage"
      description: "Query Cortex Agent usage specifically. See which agents cost most, who uses them, daily agent trends. Use when question is about agents."
  - tool_spec:
      type: "chart_generation"
      name: "generate_chart"
      description: "Generate visual charts (bar, line, pie) from query results. Use after running a query to visualize trends, comparisons, and rankings."
tool_resources:
  query_all_usage:
    semantic_view: "PUBLIC_METADATA.AI.CORTEX_AI_USAGE_MODEL"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
      query_timeout: 120
  query_code_usage:
    semantic_view: "PUBLIC_METADATA.AI.CORTEX_CODE_USAGE_MODEL"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
      query_timeout: 120
  query_agent_usage:
    semantic_view: "PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE_MODEL"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
      query_timeout: 120
$$;
