# Quick Start Guide

Get up and running with the Semantic View Enhancement Tool in 3 minutes.

---

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Snowflake account with Cortex AI features enabled
- [ ] Permissions to:
  - Create database and schema
  - Create warehouses
  - Create stored procedures
  - Create semantic views
- [ ] Access to `SNOWFLAKE_SAMPLE_DATA` (for examples) or your own semantic views
- [ ] An existing semantic view to enhance (or use our examples)

### Setting Up Sample Data (If Needed)

The examples use `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` tables. If you don't have access:

```sql
-- Run these commands as ACCOUNTADMIN (or similar role)
SHOW SHARES LIKE 'SAMPLE_DATA';

CREATE DATABASE SNOWFLAKE_SAMPLE_DATA 
  FROM SHARE SFSALESSHARED.SFC_SAMPLES_VA2.SAMPLE_DATA;

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO PUBLIC;
```

This sample data share is automatically available to all Snowflake customers in your region.

---

## Step 1: Install (30 seconds)

### Run the Setup Script

```sql
-- Option A: In Snowsight
-- 1. Open sql/01_setup/00_setup.sql
-- 2. Click "Run All"

-- Option B: Using @ command
@sql/01_setup/00_setup.sql
```

### What This Creates

```
SNOWFLAKE_EXAMPLE
  └── SEMANTIC_ENHANCEMENTS
       ├── SFE_ENHANCEMENT_WH (warehouse: X-SMALL, 60s auto-suspend)
       └── SFE_ENHANCE_SEMANTIC_VIEW (procedure: Python 3.11, AI_COMPLETE, llama3.3-70b)
```

### Verify Installation

```sql
-- Check that procedure was created
SHOW PROCEDURES LIKE 'SFE_ENHANCE_SEMANTIC_VIEW' 
  IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;

-- Expected: 1 row showing the procedure
```

---

## Step 2: Try the Examples (2 minutes)

### Run the Example Script

```sql
@sql/02_examples/01_example_usage.sql
```

This script will:
1. Create 2 sample semantic views using TPCH data
2. Enhance them with business context
3. Show you before/after comparisons

### Watch It Work

The script creates:
- `ORDERS_ENHANCED_SV` (original with basic descriptions)
- `ORDERS_ENHANCED_SV_ENHANCED` (enhanced copy with AI descriptions)
- `CUSTOMER_ORDERS_SV` (original)
- `CUSTOMER_ORDERS_SV_ENHANCED` (enhanced copy)

### Compare Results

```sql
-- View original descriptions
DESCRIBE SEMANTIC VIEW ORDERS_ENHANCED_SV;

-- View enhanced descriptions
DESCRIBE SEMANTIC VIEW ORDERS_ENHANCED_SV_ENHANCED;

-- Look for the COMMENT column - you'll see the difference!
```

---

## Step 3: Enhance Your Own Views

### Basic Usage

```sql
USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;

CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'YOUR_SEMANTIC_VIEW_NAME',
    P_BUSINESS_CONTEXT_PROMPT => 'Your business context here...'
);
```

### Example with Real Context

```sql
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'SALES_ORDERS',
    P_BUSINESS_CONTEXT_PROMPT => 
'Sales order tracking system for B2B operations.

Order Status:
- DRAFT: Order being created, not yet submitted
- PENDING: Submitted, awaiting approval
- APPROVED: Manager approved, ready to fulfill
- SHIPPED: Sent to customer
- DELIVERED: Confirmed delivery
- CANCELLED: Order cancelled by customer or system

Priority Levels:
- HIGH: VIP customers, 24-hour SLA
- NORMAL: Standard customers, 3-day SLA
- LOW: Backorders, 7-day SLA

Sales Region Codes:
- AMER-EAST, AMER-WEST: Americas regions
- EMEA: Europe, Middle East, Africa
- APAC: Asia Pacific

Business Rules:
- Only DELIVERED orders count toward revenue
- Orders over $50K require VP approval
- HIGH priority orders get expedited shipping
'
);
```

### Check the Results

```sql
-- Original view
DESCRIBE SEMANTIC VIEW SALES_ORDERS;

-- Enhanced copy
DESCRIBE SEMANTIC VIEW SALES_ORDERS_ENHANCED;
```

---

## What Happens During Enhancement

```
1. Extract Source DDL
   ↓
   GET_DDL retrieves the semantic view definition

2. Analyze Structure
   ↓
   DESCRIBE SEMANTIC VIEW lists all dimensions and facts

3. Enhance Each Field
   ↓
   For each dimension/fact:
   - Sends current description + your business context to Cortex
   - Cortex generates enhanced description
   - Replaces old comment with new one

4. Create Enhanced Copy
   ↓
   Executes modified DDL with new view name
   Original view remains unchanged
```

---

## Understanding the Output

### Success Message

```
Successfully created SALES_ORDERS_ENHANCED with 8 enhanced dimension/fact comments
```

This means:
- ✅ 8 dimensions/facts were successfully enhanced
- ✅ New view created with `_ENHANCED` suffix
- ✅ Original view unchanged

### Partial Success Message

```
Successfully created SALES_ORDERS_ENHANCED with 7 enhanced dimension/fact comments. 
Note: 1 dimension(s) had enhancement errors and kept original comments.
```

This means:
- ✅ 7 out of 8 fields enhanced successfully
- ⚠️ 1 field kept its original description (Cortex error or API issue)
- ✅ View still created, just with one field not enhanced

### Error Message

```
Error creating view: [error details]

Generated DDL:
[shows the DDL that failed]
```

This means:
- ❌ View creation failed
- 📋 Review the DDL to see what went wrong
- 🔧 Usually a table reference or syntax issue

---

## Tips for Success

### 1. Start Simple

Don't write a novel for your first prompt. Start with:
- Basic code definitions
- Key business rules
- Common abbreviations

### 2. Be Specific About Codes

❌ **Vague**: "Various status codes"  
✅ **Clear**: "Status: DRAFT (being created), PENDING (awaiting approval), APPROVED (ready to ship)"

### 3. Include Context Connections

❌ **Isolated**: "Priority level"  
✅ **Connected**: "Priority level determines SLA: HIGH (24hr), NORMAL (3-day), LOW (7-day)"

### 4. Define Thresholds

❌ **Generic**: "Large orders need approval"  
✅ **Specific**: "Orders over $50K require VP approval"

### 5. Iterate and Refine

First attempt not perfect? Drop the enhanced view and try again with better context:

```sql
DROP SEMANTIC VIEW SALES_ORDERS_ENHANCED;

CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'SALES_ORDERS',
    P_BUSINESS_CONTEXT_PROMPT => 'Improved, more detailed context...'
);
```

---

## Next Steps

### Learn More

- Read the full [README.md](../README.md) for detailed documentation
- Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide if you hit issues

### Apply to Production

Once you're happy with the results:

1. **Document your prompts**: Save successful business context prompts
2. **Standardize terminology**: Use consistent prompts across related views
3. **Version control**: Store your enhanced view DDL in git
4. **Drop originals**: Replace basic views with enhanced ones (after testing!)

### Clean Up Examples

When done experimenting:

```sql
@sql/99_cleanup/teardown_all.sql
```

This removes all example views and the procedure (you can reinstall anytime).

---

## Troubleshooting Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| "Procedure not found" | Run `@sql/01_setup/00_setup.sql` again |
| "Semantic view not found" | Check spelling and schema |
| "Cortex not available" | Contact Snowflake support to enable Cortex |
| "Descriptions don't make sense" | Refine your business context prompt |
| "View creation failed" | Check error message for DDL issues |

---

## Getting Help

If you're stuck:

1. Check the error message carefully
2. Review the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide  
3. Look at the generated DDL in error messages
4. Try the examples first to ensure basic setup works
5. Simplify your business context prompt

---

## Success Checklist

You're ready for production when you can:

- [ ] Successfully enhance the example views
- [ ] Enhance one of your own semantic views
- [ ] Understand the success/error messages
- [ ] Write effective business context prompts
- [ ] Compare original vs enhanced descriptions
- [ ] Choose which version to use in production

---

**Ready to scale?** Apply this to all your semantic views to create a consistent, well-documented semantic layer!

