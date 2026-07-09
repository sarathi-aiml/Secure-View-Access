# AI Observability Events - Secure View Access Pattern

## Problem

Snowflake's `SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS` contains all Cortex AI usage telemetry (LLM calls, token counts, latency, models used). However, granting employees direct access requires `IMPORTED PRIVILEGES` on the `SNOWFLAKE` database, which exposes **all** account metadata — billing, query history, login history, and more.

## Solution

Create a **secure view** in a separate database with a dedicated reader role. Employees query AI events through the view without access to the underlying system table or any other Snowflake metadata.

```
┌─────────────────────────┐         ┌───────────────────────────────────────┐
│   AI_EVENTS_READER      │ SELECT  │  PUBLIC_METADATA.AI.AI_EVENTS         │
│   (dedicated role)       │────────▶│  (secure view)                        │
│                          │         │                                       │
│  ✓ Can query view        │         │  SELECT * FROM                        │
│  ✗ Cannot modify view    │         │  SNOWFLAKE.LOCAL.AI_OBSERVABILITY_... │
│  ✗ Cannot see source     │         └───────────────────────────────────────┘
│  ✗ Cannot drop/alter     │                        │
└─────────────────────────┘                        │ owned by ACCOUNTADMIN
                                                    │ (invoker sees data via
                                                    │  ownership chain)
```

## What Employees Get

| Capability | Access |
|---|---|
| Query AI events (token usage, models, latency) | Yes |
| Modify or drop the view | No |
| Access `SNOWFLAKE.LOCAL` directly | No |
| See other account metadata (billing, query history, logins) | No |
| See view SQL definition (via SHOW VIEWS) | No |

## Setup

Run `ai_events_secure_view_setup.sql` as **ACCOUNTADMIN**. It will:

1. Create role `AI_EVENTS_READER`
2. Create database `PUBLIC_METADATA` with schema `AI`
3. Create secure view `PUBLIC_METADATA.AI.AI_EVENTS`
4. Grant minimal SELECT-only access to the reader role
5. Create a test user `AI_TEST_USER` for verification

## Assigning to Employees

Grant the reader role to any user or role:

```sql
-- Grant to a specific user
GRANT ROLE AI_EVENTS_READER TO USER jane_smith;

-- Grant to an existing functional role (e.g., DATA_ANALYST)
GRANT ROLE AI_EVENTS_READER TO ROLE DATA_ANALYST;
```

## Important: Secondary Roles

If an employee also has `ACCOUNTADMIN` or a role with `IMPORTED PRIVILEGES` on the SNOWFLAKE database, Snowflake's default secondary role behavior may grant them direct access regardless. For true isolation:

- Assign `AI_EVENTS_READER` to users who do **not** have admin roles, OR
- Instruct users to run `USE SECONDARY ROLES NONE` before querying

## Customization

### Filter by model or user

Replace the view definition to expose only specific data:

```sql
CREATE OR REPLACE SECURE VIEW PUBLIC_METADATA.AI.AI_EVENTS AS
SELECT * FROM SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS
WHERE RESOURCE_ATTRIBUTES:"snow.user.name"::STRING = CURRENT_USER();
```

### Add column-level restrictions

Omit sensitive columns from the view:

```sql
CREATE OR REPLACE SECURE VIEW PUBLIC_METADATA.AI.AI_EVENTS AS
SELECT
    TIMESTAMP,
    RECORD_TYPE,
    RESOURCE_ATTRIBUTES:"snow.model.name"::STRING AS MODEL,
    VALUE:"usage.completion_tokens"::INT AS COMPLETION_TOKENS,
    VALUE:"usage.prompt_tokens"::INT AS PROMPT_TOKENS
FROM SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS;
```

## Cleanup

Uncomment the cleanup section at the bottom of `ai_events_secure_view_setup.sql` and run as ACCOUNTADMIN.

## Tested Constraints

| Test | Role: AI_EVENTS_READER (secondary roles OFF) |
|---|---|
| `SELECT * FROM PUBLIC_METADATA.AI.AI_EVENTS` | **PASS** - returns rows |
| `SELECT * FROM SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS` | **BLOCKED** - "does not exist or not authorized" |
| `DROP VIEW PUBLIC_METADATA.AI.AI_EVENTS` | **BLOCKED** - "must have OWNERSHIP" |
| `ALTER VIEW ... SET COMMENT` | **BLOCKED** - "must have OWNERSHIP" |
