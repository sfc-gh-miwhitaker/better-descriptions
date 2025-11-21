/*******************************************************************************
 * DEMO PROJECT: better-descriptions
 * Script: Example Usage
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * Author: SE Community | Expires: 2025-12-21
 * 
 * PURPOSE:
 *   Demonstrate how to use Cortex AI to create enhanced copies of semantic
 *   views with improved dimension/fact descriptions
 * 
 * HOW IT WORKS:
 *   1. Create semantic views with basic comments using TPCH sample data
 *   2. Call SFE_ENHANCE_SEMANTIC_VIEW with business context
 *   3. Get new semantic views with AI-enhanced descriptions
 *   4. Compare original vs enhanced versions
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS.ORDERS_ENHANCED_SV
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS.ORDERS_ENHANCED_SV_ENHANCED
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS.CUSTOMER_ORDERS_SV
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS.CUSTOMER_ORDERS_SV_ENHANCED
 * 
 * PREREQUISITES:
 *   - Run sql/01_setup/00_setup.sql first
 *   - Access to SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 tables
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

-- ═══════════════════════════════════════════════════════════════════════════
-- Expiration Check (Demo expires: 2025-12-21)
-- ═══════════════════════════════════════════════════════════════════════════
SELECT 
    CASE 
        WHEN CURRENT_DATE > '2025-12-21'::DATE 
        THEN 1 / 0  -- Force error: Demo expired
        ELSE 1
    END AS expiration_check,
    '✓ Demo is active (expires: 2025-12-21)' AS status;

-- ═══════════════════════════════════════════════════════════════════════════
-- Examples Script
-- ═══════════════════════════════════════════════════════════════════════════

USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;
USE WAREHOUSE SFE_ENHANCEMENT_WH;

-- First, create a properly structured semantic view using TPCH sample data
-- This follows the correct CREATE SEMANTIC VIEW syntax from Snowflake documentation
CREATE OR REPLACE SEMANTIC VIEW ORDERS_ENHANCED_SV
  TABLES (
    orders AS SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
      PRIMARY KEY (O_ORDERKEY)
      COMMENT = 'Orders table from TPCH sample data'
  )
  FACTS (
    orders.O_TOTALPRICE AS O_TOTALPRICE
      COMMENT = 'Total order price'
  )
  DIMENSIONS (
    orders.O_ORDERKEY AS O_ORDERKEY
      COMMENT = 'Unique order identifier',
    orders.O_CUSTKEY AS O_CUSTKEY
      COMMENT = 'Customer identifier',
    orders.O_ORDERSTATUS AS O_ORDERSTATUS
      COMMENT = 'Order status code',
    orders.O_ORDERDATE AS O_ORDERDATE
      COMMENT = 'Date order was placed',
    orders.O_ORDERPRIORITY AS O_ORDERPRIORITY
      COMMENT = 'Order priority level',
    orders.O_CLERK AS O_CLERK
      COMMENT = 'Clerk identifier',
    orders.O_SHIPPRIORITY AS O_SHIPPRIORITY
      COMMENT = 'Shipping priority'
  )
  COMMENT = 'Semantic view for order fulfillment analysis';

-- Show current descriptions (generic from CREATE statement)
DESCRIBE SEMANTIC VIEW ORDERS_ENHANCED_SV;

-- Example 1: Create an enhanced copy with order fulfillment context
-- This creates ORDERS_ENHANCED_SV_ENHANCED with AI-improved comments
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'ORDERS_ENHANCED_SV',
    P_BUSINESS_CONTEXT_PROMPT => 'This data represents our order fulfillment system. Status codes: F=Fulfilled (shipped), O=Open (awaiting payment), P=Processing (warehouse). Priority levels: 1-URGENT (VIP, 24hr SLA), 2-HIGH (48hr), 3-MEDIUM (5 day). Clerk codes are employee IDs for commission tracking. Only fulfilled orders count toward revenue targets.'
    -- P_OUTPUT_VIEW_NAME is optional, defaults to SOURCE_NAME_ENHANCED
);

-- Compare original vs enhanced
DESCRIBE SEMANTIC VIEW ORDERS_ENHANCED_SV;
DESCRIBE SEMANTIC VIEW ORDERS_ENHANCED_SV_ENHANCED;

-- The enhanced view now has AI-improved, business-aware descriptions!

-- Example 2: Create another semantic view with customer and order data
CREATE OR REPLACE SEMANTIC VIEW CUSTOMER_ORDERS_SV
  TABLES (
    customers AS SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
      PRIMARY KEY (C_CUSTKEY)
      COMMENT = 'Customer data',
    orders AS SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
      PRIMARY KEY (O_ORDERKEY)
      COMMENT = 'Order data'
  )
  RELATIONSHIPS (
    orders_to_customers AS
      orders (O_CUSTKEY) REFERENCES customers
  )
  FACTS (
    orders.O_TOTALPRICE AS O_TOTALPRICE
      COMMENT = 'Order total price'
  )
  DIMENSIONS (
    customers.C_CUSTKEY AS C_CUSTKEY
      COMMENT = 'Customer ID',
    customers.C_NAME AS C_NAME
      COMMENT = 'Customer name',
    customers.C_MKTSEGMENT AS C_MKTSEGMENT
      COMMENT = 'Market segment code',
    orders.O_ORDERSTATUS AS O_ORDERSTATUS
      COMMENT = 'Order status'
  )
  COMMENT = 'Customer segmentation with order analysis';

-- Enhance with customer segmentation context - creates CUSTOMER_ORDERS_SV_ENHANCED
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'CUSTOMER_ORDERS_SV',
    P_BUSINESS_CONTEXT_PROMPT => 'This combines customer segmentation with order data. Market segments: BUILDING (construction industry), AUTOMOBILE (auto dealers), HOUSEHOLD (retail consumers). We use this for analyzing purchasing patterns by customer type. Status F means completed transaction.'
);

-- Compare the views
DESCRIBE SEMANTIC VIEW CUSTOMER_ORDERS_SV;
DESCRIBE SEMANTIC VIEW CUSTOMER_ORDERS_SV_ENHANCED;

-- DONE! You now have enhanced copies with AI-improved, business-aware descriptions.
-- Original views remain unchanged. Use whichever version works best for you!
