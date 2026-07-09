-- =============================================================================
-- Cortex AI Usage Intelligence - Semantic Views
-- Run as: ACCOUNTADMIN (after 01 and 02 scripts)
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Unified semantic view (all products)
CREATE OR REPLACE SEMANTIC VIEW PUBLIC_METADATA.AI.CORTEX_AI_USAGE_MODEL
    TABLES (
        PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE 
        COMMENT='Unified view of ALL Cortex AI token and credit usage across every product: Code CLI, Code Snowsight, Code Desktop, Agents, AI Functions, Analyst, AI SQL, Cortex Guard, Cortex Search, REST API, Document AI, and Fine-Tuning.'
    )
    FACTS (
        CORTEX_AI_UNIFIED_USAGE.TOKENS_TOTAL AS TOKENS_TOTAL COMMENT='Total tokens consumed in this event.',
        CORTEX_AI_UNIFIED_USAGE.CREDITS AS CREDITS COMMENT='Snowflake credits consumed. Primary cost metric.'
    )
    DIMENSIONS (
        CORTEX_AI_UNIFIED_USAGE.PRODUCT AS PRODUCT COMMENT='Cortex AI product name: Cortex Code CLI, Cortex Code Snowsight, Cortex Code Desktop, Cortex Agents, AI Functions, Cortex Analyst, AI SQL, Cortex Guard, Cortex Search, Cortex REST API, Document AI, Fine-Tuning.',
        CORTEX_AI_UNIFIED_USAGE.USER_NAME AS USER_NAME COMMENT='Snowflake username who consumed tokens.',
        CORTEX_AI_UNIFIED_USAGE.ROLE_NAME AS ROLE_NAME COMMENT='Snowflake role used during the request.',
        CORTEX_AI_UNIFIED_USAGE.MODEL_NAME AS MODEL_NAME COMMENT='LLM model used (claude-opus-4-6, claude-sonnet-4-5, snowflake-arctic, etc.).',
        CORTEX_AI_UNIFIED_USAGE.AGENT_NAME AS AGENT_NAME COMMENT='Name of the Cortex Agent. Only for Cortex Agents product.',
        CORTEX_AI_UNIFIED_USAGE.FUNCTION_NAME AS FUNCTION_NAME COMMENT='AI function name (AI_COMPLETE, AI_EXTRACT, AI_CLASSIFY). Only for AI Functions.',
        CORTEX_AI_UNIFIED_USAGE.USAGE_DATE AS USAGE_DATE COMMENT='Date of usage event for daily/weekly/monthly trending.'
    )
    COMMENT='Cortex AI Usage Intelligence - unified token and credit consumption across all Snowflake AI products. Slice by product, user, role, model, agent, function, and date.'
    AI_VERIFIED_QUERIES (
        USAGE_BY_PRODUCT AS (
            QUESTION 'What is the total token usage and credits by product?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT PRODUCT, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits, COUNT(*) AS events FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE GROUP BY PRODUCT ORDER BY total_credits DESC NULLS LAST'
        ),
        DAILY_TREND AS (
            QUESTION 'What is the daily credit usage trend?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT USAGE_DATE, SUM(CREDITS) AS daily_credits, SUM(TOKENS_TOTAL) AS daily_tokens FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE GROUP BY USAGE_DATE ORDER BY USAGE_DATE'
        ),
        TOP_USERS AS (
            QUESTION 'Who are the top users by credit consumption?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT USER_NAME, SUM(CREDITS) AS total_credits, SUM(TOKENS_TOTAL) AS total_tokens, COUNT(*) AS events FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE USER_NAME IS NOT NULL GROUP BY USER_NAME ORDER BY total_credits DESC'
        ),
        USAGE_BY_MODEL AS (
            QUESTION 'Which LLM models consume the most tokens?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT MODEL_NAME, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE MODEL_NAME IS NOT NULL GROUP BY MODEL_NAME ORDER BY total_tokens DESC NULLS LAST'
        ),
        CREDITS_BY_ROLE AS (
            QUESTION 'What is the credit breakdown by role?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT ROLE_NAME, SUM(CREDITS) AS total_credits, COUNT(*) AS events FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE ROLE_NAME IS NOT NULL GROUP BY ROLE_NAME ORDER BY total_credits DESC'
        ),
        AGENT_USAGE AS (
            QUESTION 'What is the usage breakdown by Cortex Agent?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT AGENT_NAME, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits, COUNT(*) AS invocations FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE AGENT_NAME IS NOT NULL GROUP BY AGENT_NAME ORDER BY total_credits DESC'
        ),
        WEEKLY_BY_PRODUCT AS (
            QUESTION 'What is the weekly usage trend by product?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT DATE_TRUNC(''WEEK'', USAGE_DATE)::DATE AS usage_week, PRODUCT, SUM(CREDITS) AS weekly_credits FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE GROUP BY usage_week, PRODUCT ORDER BY usage_week, PRODUCT'
        ),
        CODE_SURFACE_COMPARE AS (
            QUESTION 'Compare Cortex Code CLI vs Snowsight vs Desktop usage'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT PRODUCT, COUNT(*) AS events, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE PRODUCT LIKE ''Cortex Code%'' GROUP BY PRODUCT ORDER BY total_credits DESC'
        ),
        TODAYS_USAGE AS (
            QUESTION 'What is the total credit and token usage today?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT PRODUCT, SUM(CREDITS) AS credits_today, SUM(TOKENS_TOTAL) AS tokens_today FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE USAGE_DATE = CURRENT_DATE() GROUP BY PRODUCT ORDER BY credits_today DESC NULLS LAST'
        ),
        AI_FUNCTIONS_BREAKDOWN AS (
            QUESTION 'What AI functions are used most and their credit cost?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT FUNCTION_NAME, COUNT(*) AS call_count, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_AI_UNIFIED_USAGE WHERE FUNCTION_NAME IS NOT NULL GROUP BY FUNCTION_NAME ORDER BY total_credits DESC NULLS LAST'
        )
    );

-- Cortex Code semantic view
CREATE OR REPLACE SEMANTIC VIEW PUBLIC_METADATA.AI.CORTEX_CODE_USAGE_MODEL
    TABLES (
        PUBLIC_METADATA.AI.CORTEX_CODE_USAGE 
        COMMENT='Cortex Code usage across CLI, Snowsight, and Desktop surfaces. Every row is a single request with tokens, credits, user, role, and model.'
    )
    FACTS (
        CORTEX_CODE_USAGE.TOKENS_TOTAL AS TOKENS_TOTAL COMMENT='Total tokens consumed.',
        CORTEX_CODE_USAGE.CREDITS AS CREDITS COMMENT='Credits consumed.'
    )
    DIMENSIONS (
        CORTEX_CODE_USAGE.SURFACE AS SURFACE COMMENT='Cortex Code surface: CLI, Snowsight, Desktop.',
        CORTEX_CODE_USAGE.USER_NAME AS USER_NAME COMMENT='User who used Cortex Code.',
        CORTEX_CODE_USAGE.ROLE_NAME AS ROLE_NAME COMMENT='Role used.',
        CORTEX_CODE_USAGE.MODEL_NAME AS MODEL_NAME COMMENT='LLM model.',
        CORTEX_CODE_USAGE.USAGE_DATE AS USAGE_DATE COMMENT='Date of usage.',
        CORTEX_CODE_USAGE.USAGE_WEEK AS USAGE_WEEK COMMENT='Week of usage.',
        CORTEX_CODE_USAGE.USAGE_MONTH AS USAGE_MONTH COMMENT='Month of usage.'
    )
    COMMENT='Cortex Code detailed usage. Drill into CLI vs Snowsight vs Desktop by user, model, role, and time.'
    AI_VERIFIED_QUERIES (
        USAGE_BY_SURFACE AS (
            QUESTION 'Compare token usage across Cortex Code CLI, Snowsight, and Desktop'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT SURFACE, COUNT(*) AS requests, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_CODE_USAGE GROUP BY SURFACE ORDER BY total_credits DESC'
        ),
        DAILY_CODE_TREND AS (
            QUESTION 'Show the daily Cortex Code usage trend'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT USAGE_DATE, SURFACE, SUM(CREDITS) AS daily_credits, SUM(TOKENS_TOTAL) AS daily_tokens FROM PUBLIC_METADATA.AI.CORTEX_CODE_USAGE GROUP BY USAGE_DATE, SURFACE ORDER BY USAGE_DATE'
        ),
        TOP_CODE_USERS AS (
            QUESTION 'Who uses Cortex Code the most?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT USER_NAME, SURFACE, COUNT(*) AS requests, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_CODE_USAGE GROUP BY USER_NAME, SURFACE ORDER BY total_credits DESC'
        ),
        MODELS_USED AS (
            QUESTION 'Which models are used in Cortex Code?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT MODEL_NAME, COUNT(*) AS requests, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_CODE_USAGE WHERE MODEL_NAME IS NOT NULL GROUP BY MODEL_NAME ORDER BY total_credits DESC'
        )
    );

-- Cortex Agents semantic view
CREATE OR REPLACE SEMANTIC VIEW PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE_MODEL
    TABLES (
        PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE 
        COMMENT='Cortex Agent invocation usage. Each row is a single agent call.'
    )
    FACTS (
        CORTEX_AGENTS_USAGE.TOKENS_TOTAL AS TOKENS_TOTAL COMMENT='Tokens consumed.',
        CORTEX_AGENTS_USAGE.CREDITS AS CREDITS COMMENT='Credits consumed.'
    )
    DIMENSIONS (
        CORTEX_AGENTS_USAGE.AGENT_NAME AS AGENT_NAME COMMENT='Agent name.',
        CORTEX_AGENTS_USAGE.USER_NAME AS USER_NAME COMMENT='User who invoked.',
        CORTEX_AGENTS_USAGE.AGENT_DATABASE_NAME AS AGENT_DATABASE_NAME COMMENT='Agent database.',
        CORTEX_AGENTS_USAGE.AGENT_SCHEMA_NAME AS AGENT_SCHEMA_NAME COMMENT='Agent schema.',
        CORTEX_AGENTS_USAGE.USAGE_DATE AS USAGE_DATE COMMENT='Date.',
        CORTEX_AGENTS_USAGE.USAGE_WEEK AS USAGE_WEEK COMMENT='Week.',
        CORTEX_AGENTS_USAGE.USAGE_MONTH AS USAGE_MONTH COMMENT='Month.'
    )
    COMMENT='Cortex Agents usage analytics. Track agent costs, users, and trends.'
    AI_VERIFIED_QUERIES (
        TOP_AGENTS AS (
            QUESTION 'Which agents consume the most credits?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT AGENT_NAME, COUNT(*) AS invocations, SUM(TOKENS_TOTAL) AS total_tokens, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE GROUP BY AGENT_NAME ORDER BY total_credits DESC'
        ),
        AGENT_USAGE_BY_USER AS (
            QUESTION 'Who uses agents the most?'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION true
            SQL 'SELECT USER_NAME, AGENT_NAME, COUNT(*) AS invocations, SUM(CREDITS) AS total_credits FROM PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE GROUP BY USER_NAME, AGENT_NAME ORDER BY total_credits DESC'
        ),
        DAILY_AGENT_TREND AS (
            QUESTION 'Show daily agent usage trend'
            VERIFIED_AT 1752105600
            VERIFIED_BY 'Platform Team'
            ONBOARDING_QUESTION false
            SQL 'SELECT USAGE_DATE, AGENT_NAME, SUM(CREDITS) AS daily_credits, COUNT(*) AS invocations FROM PUBLIC_METADATA.AI.CORTEX_AGENTS_USAGE GROUP BY USAGE_DATE, AGENT_NAME ORDER BY USAGE_DATE'
        )
    );
