/*******************************************************************************
 * DEMO PROJECT: Better Descriptions - Git-Integrated Deployment
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * EXPIRES: 2025-12-21 (30 days from creation)
 * Author: SE Community
 * Status: ACTIVE
 * 
 * ═══════════════════════════════════════════════════════════════════════════
 * USAGE IN SNOWSIGHT (FASTEST PATH):
 * ═══════════════════════════════════════════════════════════════════════════
 *   1. Copy this ENTIRE script (Ctrl+A / Cmd+A)
 *   2. Open Snowsight -> New Worksheet
 *   3. Paste the script
 *   4. Click "Run All" (top right)
 *   5. Wait ~5 minutes for complete deployment
 * 
 * WHAT THIS SCRIPT DOES:
 *   - Creates API Integration for GitLab access
 *   - Creates Git Repository stage pointing to project source
 *   - Creates dedicated warehouse (SFE_ENHANCEMENT_WH)
 *   - Creates database and schema (SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS)
 *   - Executes setup SQL from Git repository
 *   - Creates SFE_ENHANCE_SEMANTIC_VIEW stored procedure
 *   - Optionally runs examples to verify installation
 * 
 * OBJECTS CREATED:
 *   Account-Level:
 *     - SFE_BETTERDESC_GIT_API_INTEGRATION (API Integration)
 *     - SFE_ENHANCEMENT_WH (Warehouse, X-SMALL, 60s auto-suspend)
 *   
 *   Database Objects (in SNOWFLAKE_EXAMPLE):
 *     - SNOWFLAKE_EXAMPLE database (if not exists)
 *     - SNOWFLAKE_EXAMPLE.GIT_REPOS schema
 *     - SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO (Git Repository)
 *     - SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS schema
 *     - SFE_ENHANCE_SEMANTIC_VIEW stored procedure (Python 3.11)
 * 
 * CLEANUP:
 *   @sql/99_cleanup/teardown_all.sql (via Git repository)
 *   OR: See "Complete Cleanup" section at bottom of this script
 * 
 * ESTIMATED TIME: ~5 minutes
 * ESTIMATED COST: < $0.01 (one-time setup)
 ******************************************************************************/

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 0: Expiration Check (MANDATORY)
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if demo has expired (blocks execution if expired)
SELECT 
    CASE 
        WHEN CURRENT_DATE > '2025-12-21'::DATE 
        THEN 1 / 0  -- Force error: "Division by zero"
        ELSE 1
    END AS expiration_check,
    '✓ Demo is active (expires: 2025-12-21)' AS status,
    DATEDIFF(DAY, CURRENT_DATE, '2025-12-21'::DATE) AS days_remaining;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: Create Database and Git Repository Schema
-- ═══════════════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
  COMMENT = 'DEMO: Repository for example/demo projects - NOT FOR PRODUCTION';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
  COMMENT = 'DEMO: Shared schema for Git repository stages across all demo projects';

USE SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 2: Create API Integration for GitLab Access
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE API INTEGRATION SFE_BETTERDESC_GIT_API_INTEGRATION
  API_PROVIDER = GIT_HTTPS_API
  API_ALLOWED_PREFIXES = ('https://snow.gitlab-dedicated.com/snowflakecorp/SE/sales-engineering/')
  ENABLED = TRUE
  COMMENT = 'DEMO: better-descriptions - GitLab integration for public repo access | Author: SE Community | Expires: 2025-12-21';

-- Verify API Integration
SHOW API INTEGRATIONS LIKE 'SFE_BETTERDESC_GIT_API_INTEGRATION';

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 3: Create Git Repository Stage
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO
  API_INTEGRATION = SFE_BETTERDESC_GIT_API_INTEGRATION
  ORIGIN = 'https://snow.gitlab-dedicated.com/snowflakecorp/SE/sales-engineering/miwhitaker-tool-betterdescriptions.git'
  COMMENT = 'DEMO: better-descriptions - Semantic view enhancement tool source repository | Author: SE Community | Expires: 2025-12-21';

-- Fetch latest from repository
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO FETCH;

-- Verify repository is accessible
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;
LS @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO/branches/main/sql/;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 4: Create Dedicated Warehouse (BEFORE executing scripts)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE WAREHOUSE IF NOT EXISTS SFE_ENHANCEMENT_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'DEMO: better-descriptions - Dedicated warehouse for semantic view enhancement workload | Author: SE Community | Expires: 2025-12-21';

USE WAREHOUSE SFE_ENHANCEMENT_WH;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 5: Execute Setup Scripts from Git Repository
-- ═══════════════════════════════════════════════════════════════════════════

-- Create schema for enhancement tool
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS
  COMMENT = 'DEMO: better-descriptions - Schema for semantic view enhancement tool | Author: SE Community | Expires: 2025-12-21';

USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;

-- Execute setup script to create stored procedure
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO/branches/main/sql/01_setup/00_setup.sql;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 6: Verify Installation
-- ═══════════════════════════════════════════════════════════════════════════

-- Verify stored procedure was created
SHOW PROCEDURES LIKE 'SFE_ENHANCE_SEMANTIC_VIEW' 
  IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;

-- Verify warehouse
SHOW WAREHOUSES LIKE 'SFE_ENHANCEMENT_WH';

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 7 (OPTIONAL): Run Examples to Verify Functionality
-- ═══════════════════════════════════════════════════════════════════════════

-- Uncomment the following line to run working examples with TPCH sample data:
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO/branches/main/sql/02_examples/01_example_usage.sql;

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ DEPLOYMENT COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════

SELECT '✅ DEPLOYMENT COMPLETE' AS STATUS,
       'Semantic view enhancement tool is ready to use' AS MESSAGE,
       'SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS.SFE_ENHANCE_SEMANTIC_VIEW' AS PROCEDURE_NAME,
       'See docs/01-QUICK-START.md for usage examples' AS NEXT_STEPS;

/*******************************************************************************
 * USAGE EXAMPLE:
 ******************************************************************************/

-- USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;
-- USE WAREHOUSE SFE_ENHANCEMENT_WH;
-- 
-- CALL SFE_ENHANCE_SEMANTIC_VIEW(
--     P_SOURCE_VIEW_NAME => 'YOUR_SEMANTIC_VIEW',
--     P_BUSINESS_CONTEXT_PROMPT => 'Your comprehensive business context here...'
-- );

/*******************************************************************************
 * TROUBLESHOOTING:
 ******************************************************************************/

-- ❌ ERROR: "API integration not found"
--    SOLUTION: Ensure you have ACCOUNTADMIN or CREATE INTEGRATION privilege
--    Run: USE ROLE ACCOUNTADMIN; then re-run this script

-- ❌ ERROR: "Could not access Git repository"
--    SOLUTION: Repository may be private or URL incorrect
--    Verify: https://snow.gitlab-dedicated.com/snowflakecorp/SE/sales-engineering/miwhitaker-tool-betterdescriptions.git
--    Check: SHOW GIT REPOSITORIES;

-- ❌ ERROR: "Warehouse not found"
--    SOLUTION: Warehouse creation may have failed
--    Check: SHOW WAREHOUSES LIKE 'SFE_ENHANCEMENT_WH';
--    Manually create if needed (see STEP 4 above)

-- ❌ ERROR: "Procedure not found"
--    SOLUTION: EXECUTE IMMEDIATE FROM may have failed
--    Check: SHOW PROCEDURES IN SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;
--    Manually run: @sql/01_setup/00_setup.sql from repository

-- ❌ ERROR: "Cortex function not available"
--    SOLUTION: Cortex AI not enabled in your account
--    Contact: Snowflake support to enable Cortex features

/*******************************************************************************
 * COMPLETE CLEANUP (removes everything):
 ******************************************************************************/

-- Option 1: Execute cleanup script from repository
-- EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO/branches/main/sql/99_cleanup/teardown_all.sql;

-- Option 2: Manual cleanup (same result)
-- DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS CASCADE;
-- DROP WAREHOUSE IF EXISTS SFE_ENHANCEMENT_WH;
-- DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO;
-- DROP API INTEGRATION IF EXISTS SFE_BETTERDESC_GIT_API_INTEGRATION;

/*******************************************************************************
 * PROTECTED OBJECTS (NOT removed by cleanup):
 ******************************************************************************/
-- - SNOWFLAKE_EXAMPLE database (may contain other demo projects)
-- - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared across demos)

/*******************************************************************************
 * ESTIMATED COSTS:
 ******************************************************************************/
-- Edition: Standard ($2/credit) or higher
-- One-time Setup: < $0.01 (warehouse barely used)
-- Per Enhancement: ~$0.01-0.02 per semantic view (Cortex AI calls)
-- Monthly Idle: $0 (warehouse auto-suspends, no storage for this tool)
--
-- Note: Costs are for the tool itself. Semantic views you create/enhance
-- use your existing tables and don't add storage costs.

