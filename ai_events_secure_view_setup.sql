-- =============================================================================
-- AI Observability Events - Secure View Setup
-- Provides controlled access to SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS
-- via a dedicated reader role without direct source table access.
-- =============================================================================
-- IMPORTANT: Run this script as ACCOUNTADMIN
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- -----------------------------------------------------------------------------
-- 1. Create dedicated reader role
-- -----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS AI_EVENTS_READER;
GRANT ROLE AI_EVENTS_READER TO ROLE ACCOUNTADMIN;

-- -----------------------------------------------------------------------------
-- 2. Create database and schema
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PUBLIC_METADATA;
CREATE SCHEMA IF NOT EXISTS PUBLIC_METADATA.AI;

-- -----------------------------------------------------------------------------
-- 3. Create secure view (hides definition from non-owners in SHOW VIEWS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE SECURE VIEW PUBLIC_METADATA.AI.AI_EVENTS AS
SELECT * FROM SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS;

-- -----------------------------------------------------------------------------
-- 4. Grant minimal privileges to AI_EVENTS_READER
--    - USAGE on DB/schema (navigation only)
--    - SELECT on view (read only, no modify/drop)
--    - USAGE on warehouse (to execute queries)
-- -----------------------------------------------------------------------------
GRANT USAGE ON DATABASE PUBLIC_METADATA TO ROLE AI_EVENTS_READER;
GRANT USAGE ON SCHEMA PUBLIC_METADATA.AI TO ROLE AI_EVENTS_READER;
GRANT SELECT ON VIEW PUBLIC_METADATA.AI.AI_EVENTS TO ROLE AI_EVENTS_READER;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE AI_EVENTS_READER;

-- -----------------------------------------------------------------------------
-- 5. Create test user with ONLY the reader role
--    NOTE: User must have NO other roles (especially ACCOUNTADMIN) to ensure
--    secondary roles don't grant unintended access.
-- -----------------------------------------------------------------------------
CREATE USER IF NOT EXISTS AI_TEST_USER
  PASSWORD = 'TempPass123!'
  DEFAULT_ROLE = AI_EVENTS_READER
  DEFAULT_WAREHOUSE = COMPUTE_WH
  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE AI_EVENTS_READER TO USER AI_TEST_USER;

-- =============================================================================
-- VERIFICATION TESTS (run as AI_EVENTS_READER with secondary roles off)
-- =============================================================================

USE ROLE AI_EVENTS_READER;
USE SECONDARY ROLES NONE;

-- Test 1: SELECT from view (SHOULD PASS)
SELECT 'Test 1: SELECT from view' AS test;
SELECT COUNT(*) AS row_count FROM PUBLIC_METADATA.AI.AI_EVENTS;

-- Test 2: Direct access to source (SHOULD FAIL)
-- SELECT * FROM SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS LIMIT 1;
-- Expected error: "Object does not exist or not authorized"

-- Test 3: Modify view (SHOULD FAIL)
-- ALTER VIEW PUBLIC_METADATA.AI.AI_EVENTS SET COMMENT = 'test';
-- Expected error: "Insufficient privileges... must have OWNERSHIP"

-- Test 4: Drop view (SHOULD FAIL)
-- DROP VIEW PUBLIC_METADATA.AI.AI_EVENTS;
-- Expected error: "Insufficient privileges... must have OWNERSHIP"

-- =============================================================================
-- CLEANUP (uncomment to remove all test objects)
-- =============================================================================
-- USE ROLE ACCOUNTADMIN;
-- DROP USER IF EXISTS AI_TEST_USER;
-- DROP VIEW IF EXISTS PUBLIC_METADATA.AI.AI_EVENTS;
-- DROP SCHEMA IF EXISTS PUBLIC_METADATA.AI;
-- DROP DATABASE IF EXISTS PUBLIC_METADATA;
-- DROP ROLE IF EXISTS AI_EVENTS_READER;
