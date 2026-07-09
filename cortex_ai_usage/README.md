# Cortex AI Usage Intelligence

A complete solution for monitoring and analyzing Cortex AI token and credit consumption across all Snowflake AI products.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Cortex Agent (AI_USAGE_AGENT)                    │
│         Natural language queries + chart generation                  │
└───────────────┬──────────────────┬──────────────────┬───────────────┘
                │                  │                  │
    ┌───────────▼──────┐  ┌───────▼────────┐  ┌─────▼──────────┐
    │ CORTEX_AI_USAGE  │  │ CORTEX_CODE    │  │ CORTEX_AGENTS  │
    │ _MODEL           │  │ _USAGE_MODEL   │  │ _USAGE_MODEL   │
    │ (all products)   │  │ (Code only)    │  │ (agents only)  │
    └───────────┬──────┘  └───────┬────────┘  └─────┬──────────┘
                │                  │                  │
    ┌───────────▼──────┐  ┌───────▼────────┐  ┌─────▼──────────┐
    │ UNIFIED_USAGE    │  │ CODE_USAGE     │  │ AGENTS_USAGE   │
    │ (12 sources)     │  │ (3 surfaces)   │  │ (per agent)    │
    └───────────┬──────┘  └────────────────┘  └────────────────┘
                │
    ┌───────────▼──────────────────────────────────────────────┐
    │              SNOWFLAKE.ACCOUNT_USAGE                      │
    │  12 source views (Code CLI, Snowsight, Desktop, Agents,  │
    │  AI Functions, Analyst, AI SQL, Guard, Search, REST API,  │
    │  Document AI, Fine-Tuning)                                │
    └──────────────────────────────────────────────────────────┘
```

## Products Covered

| Product | Token Tracking | Credit Tracking | User | Role | Model |
|---------|:-:|:-:|:-:|:-:|:-:|
| Cortex Code CLI | Y | Y | Y | Y | Y |
| Cortex Code Snowsight | Y | Y | Y | Y | Y |
| Cortex Code Desktop | Y | Y | Y | Y | Y |
| Cortex Agents | Y | Y | Y | - | - |
| AI Functions | - | Y | - | Y | Y |
| Cortex Analyst | - | Y | Y | - | - |
| AI SQL | Y | Y | - | - | Y |
| Cortex Guard | Y | Y | Y | - | - |
| Cortex Search | - | Y | - | - | - |
| Cortex REST API | Y | - | - | - | Y |
| Document AI | - | Y | - | - | Y |
| Fine-Tuning | Y | Y | - | - | Y |

## Setup

Run scripts in order as ACCOUNTADMIN:

```sql
-- 1. Create unified view (UNION ALL of 12 sources)
@01_unified_view.sql

-- 2. Create per-product views (no NULL columns)
@02_per_product_views.sql

-- 3. Create semantic views (for Cortex Analyst)
@03_semantic_views.sql

-- 4. Create the Cortex Agent
@04_cortex_agent.sql

-- 5. Grant access to users/roles
@05_grants.sql
```

## Usage

### Via Cortex Agent (Snowsight or REST API)

Ask natural language questions:

- "What is the total credit usage by product?"
- "Show me the daily token trend for Cortex Code CLI"
- "Who are the top users by credit consumption?"
- "Compare CLI vs Snowsight vs Desktop usage"
- "Which agents cost the most?"
- "What AI functions are used most?"
- "Show weekly usage trend as a bar chart"

### Via Direct SQL

```sql
-- All products summary
SELECT PRODUCT, SUM(CREDITS) AS total_credits, SUM(TOKENS_TOTAL) AS total_tokens
FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE
GROUP BY PRODUCT ORDER BY total_credits DESC NULLS LAST;

-- Cortex Code breakdown by surface and model
SELECT SURFACE, MODEL_NAME, SUM(CREDITS) AS credits
FROM PUBLIC_METADATA.AI.CORTEX_CODE_USAGE
GROUP BY 1, 2 ORDER BY credits DESC;

-- Agent usage by name
SELECT AGENT_NAME, SUM(CREDITS) AS credits, COUNT(*) AS calls
FROM PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE
GROUP BY 1 ORDER BY credits DESC;
```

## Access Control

The `AI_USAGE_VIEWER` role provides:
- SELECT on all views and semantic views
- USAGE on the Cortex Agent
- No access to modify views or underlying SNOWFLAKE.ACCOUNT_USAGE directly

Assign to users:
```sql
GRANT ROLE AI_USAGE_VIEWER TO USER <username>;
```

## Latency

- ACCOUNT_USAGE views have ~45 minute latency
- For real-time data, query `SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS` directly (currently covers Cortex Agents only)
