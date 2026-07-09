-- =============================================================================
-- Cortex AI Usage Intelligence - Access Grants
-- Creates a viewer role for DBAs/platform teams
-- Run as: ACCOUNTADMIN (after all other scripts)
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Create viewer role
CREATE ROLE IF NOT EXISTS AI_USAGE_VIEWER;
GRANT ROLE AI_USAGE_VIEWER TO ROLE ACCOUNTADMIN;

-- Database and schema access
GRANT USAGE ON DATABASE PUBLIC_METADATA TO ROLE AI_USAGE_VIEWER;
GRANT USAGE ON SCHEMA PUBLIC_METADATA.AI TO ROLE AI_USAGE_VIEWER;

-- All views (current and future)
GRANT SELECT ON ALL VIEWS IN SCHEMA PUBLIC_METADATA.AI TO ROLE AI_USAGE_VIEWER;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA PUBLIC_METADATA.AI TO ROLE AI_USAGE_VIEWER;

-- Semantic views
GRANT SELECT ON ALL SEMANTIC VIEWS IN SCHEMA PUBLIC_METADATA.AI TO ROLE AI_USAGE_VIEWER;
GRANT SELECT ON FUTURE SEMANTIC VIEWS IN SCHEMA PUBLIC_METADATA.AI TO ROLE AI_USAGE_VIEWER;

-- Agent
GRANT USAGE ON AGENT PUBLIC_METADATA.AI.AI_USAGE_AGENT TO ROLE AI_USAGE_VIEWER;

-- Warehouse
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE AI_USAGE_VIEWER;

-- =============================================================================
-- ASSIGN TO USERS
-- Uncomment and modify to grant access to specific users or roles
-- =============================================================================

-- Grant to specific users:
-- GRANT ROLE AI_USAGE_VIEWER TO USER jane_smith;
-- GRANT ROLE AI_USAGE_VIEWER TO USER john_doe;

-- Grant to an existing functional role:
-- GRANT ROLE AI_USAGE_VIEWER TO ROLE DATA_ENGINEER;
-- GRANT ROLE AI_USAGE_VIEWER TO ROLE PLATFORM_ADMIN;
