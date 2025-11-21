/*******************************************************************************
 * DEMO PROJECT: better-descriptions
 * Script: Complete Cleanup
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * Author: SE Community | Expires: 2025-12-21
 * 
 * NOTE: NO EXPIRATION CHECK (intentional - cleanup must work even after expiration)
 * 
 * PURPOSE:
 *   Complete teardown of the semantic view enhancement demo
 * 
 * WARNING: This will permanently delete:
 *   - Schema SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS (CASCADE)
 *   - All semantic views in the schema
 *   - SFE_ENHANCE_SEMANTIC_VIEW procedure
 *   - SFE_ENHANCEMENT_WH warehouse
 *   - Any example views created
 *   - SFE_BETTERDESC_GIT_API_INTEGRATION (API Integration)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO (Git Repository)
 * 
 * PRESERVED (Intentional):
 *   - SNOWFLAKE_EXAMPLE database (may contain other demo projects)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared across demos)
 * 
 * SAFETY:
 *   - Uses IF EXISTS for safe re-execution
 *   - Preserves shared infrastructure
 * 
 * Only run this when you're done and want to remove everything.
 ******************************************************************************/

USE WAREHOUSE SFE_ENHANCEMENT_WH;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: Drop Schema (CASCADE removes all objects within)
-- ═══════════════════════════════════════════════════════════════════════════

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS CASCADE;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 2: Drop Warehouse
-- ═══════════════════════════════════════════════════════════════════════════

DROP WAREHOUSE IF EXISTS SFE_ENHANCEMENT_WH;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 3: Drop Git Repository
-- ═══════════════════════════════════════════════════════════════════════════

DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BETTERDESC_REPO;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 4: Drop API Integration (Requires ACCOUNTADMIN or appropriate privileges)
-- ═══════════════════════════════════════════════════════════════════════════

DROP API INTEGRATION IF EXISTS SFE_BETTERDESC_GIT_API_INTEGRATION;

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ CLEANUP COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════

SELECT '✅ CLEANUP COMPLETE' AS STATUS,
       'All better-descriptions demo objects have been removed' AS MESSAGE,
       'Protected: SNOWFLAKE_EXAMPLE database, SNOWFLAKE_EXAMPLE.GIT_REPOS schema' AS PRESERVED_OBJECTS;

-- Note: If you see "Insufficient privileges" errors for API Integration,
-- you need ACCOUNTADMIN role or CREATE INTEGRATION privilege

