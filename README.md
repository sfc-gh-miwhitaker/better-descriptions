# Semantic View Description Enhancement Tool

![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2025--12--21-orange)

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

> **DEMONSTRATION PROJECT - EXPIRES: 2025-12-21**  
> This demo uses Snowflake features current as of November 2025.  
> After expiration, this repository will be archived and made private.

**Author:** SE Community  
**Purpose:** Reference implementation for semantic view enhancement with Cortex AI  
**Created:** 2025-11-21 | **Expires:** 2025-12-21 (30 days) | **Status:** ACTIVE

---

**Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and business logic for your organization's specific requirements before deployment.

**Database:** All artifacts created in `SNOWFLAKE_EXAMPLE` database  
**Isolation:** Uses `SFE_` prefix for demo procedure

---

## 👋 First Time Here?

**FASTEST PATH:** Copy/paste `deploy_all.sql` into Snowsight and click "Run All" (~5 minutes)

**OR** follow these steps manually:

1. **Read**: `docs/01-QUICK-START.md` - Complete setup and usage guide (5 min)
2. **Setup**: `@sql/01_setup/00_setup.sql` - Creates the enhancement procedure
3. **Try It**: `@sql/02_examples/01_example_usage.sql` - See it work with sample data (2 min)
4. **Troubleshoot** (if needed): `docs/02-TROUBLESHOOTING.md` - Common issues and solutions
5. **Cleanup** (when done): `@sql/99_cleanup/teardown_all.sql` - Remove all demo objects

**Total time: ~10 minutes** (manual) or **~5 minutes** (deploy_all.sql)

---

## Overview

Automatically create enhanced copies of Snowflake semantic views with AI-improved dimension and fact descriptions using Cortex.

---

## What This Tool Does

Creates **enhanced copies** of your semantic views with AI-generated, business-aware descriptions for all dimensions and facts.

```sql
-- You have a semantic view with basic descriptions
ORDERS_VIEW
  - O_ORDERSTATUS: "Order status code"
  - O_ORDERPRIORITY: "Order priority level"

-- Run the enhancement
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'ORDERS_VIEW',
    P_BUSINESS_CONTEXT_PROMPT => 'Order fulfillment system. Status: F=Fulfilled (shipped), O=Open (awaiting payment), P=Processing (warehouse). Priority: 1-URGENT (VIP, 24hr SLA), 2-HIGH (48hr), 3-MEDIUM (5 day).'
);

-- Get an enhanced copy with business-aware descriptions
ORDERS_VIEW_ENHANCED
  - O_ORDERSTATUS: "Order fulfillment stage: F=Fulfilled (shipped), O=Open (awaiting payment), P=Processing (warehouse)."
  - O_ORDERPRIORITY: "Priority level determining SLA: 1-URGENT (VIP, 24hr), 2-HIGH (48hr), 3-MEDIUM (5 day)."
```

**Your original view remains unchanged.** A new enhanced copy is created with the `_ENHANCED` suffix.

---

## How It Works

The procedure uses Snowflake's native capabilities to create enhanced semantic views:

1. **Extracts** the source semantic view's DDL using `GET_DDL('SEMANTIC_VIEW', ...)`
2. **Analyzes** all dimensions and facts using `DESCRIBE SEMANTIC VIEW`
3. **Enhances** each description by calling Cortex AI with your business context
4. **Creates** a new semantic view with enhanced descriptions

```
┌─────────────────┐
│  Source View    │  ORDERS_VIEW
│  Generic desc.  │  "Order status code"
└────────┬────────┘
         │
         │ GET_DDL + DESCRIBE
         ↓
┌─────────────────┐
│  Cortex AI      │  + Your Business Context
│  Enhancement    │  → "F=Fulfilled, O=Open, P=Processing"
└────────┬────────┘
         │
         │ CREATE with enhanced DDL
         ↓
┌─────────────────┐
│  Enhanced Copy  │  ORDERS_VIEW_ENHANCED
│  Business desc. │  "Order fulfillment stage: F=Fulfilled..."
└─────────────────┘
```

---

## Prerequisites

- Snowflake account with **Cortex AI features enabled**
- Permissions to create warehouses, procedures, and semantic views
- **Access to sample data** (see setup instructions below)

**Note:** The setup script creates a dedicated `SFE_ENHANCEMENT_WH` warehouse automatically.

---

## Sample Data Setup

The examples in this project use `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` tables, which come from Snowflake's shared sample data available to all customers.

### Option 1: Using SNOWFLAKE_SAMPLE_DATA (Recommended)

If you already have access to `SNOWFLAKE_SAMPLE_DATA`, you're all set - the examples will work immediately.

### Option 2: Mount Snowflake's Sample Data Share

If `SNOWFLAKE_SAMPLE_DATA` is not available in your account, you can mount the sample data share:

```sql
-- 1. Verify the sample data share is available (requires ACCOUNTADMIN or similar role)
SHOW SHARES LIKE 'SAMPLE_DATA';

-- 2. Create a database from the share
CREATE DATABASE SNOWFLAKE_SAMPLE_DATA 
  FROM SHARE SFSALESSHARED.SFC_SAMPLES_VA2.SAMPLE_DATA;

-- 3. Grant access to other users (optional)
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO PUBLIC;
```

**Note**: This sample data is automatically available as an inbound share to all Snowflake customers in your deployment/region. It is not listed on the public Data Marketplace but is intended for testing and benchmarking purposes.

### Option 3: Use Your Own Data

If you prefer to use your own semantic views instead of the examples:
1. Skip the example script (`sql/01_example_usage.sql`)
2. Run the setup script (`sql/00_setup.sql`)
3. Use the procedure directly on your semantic views

---

## Installation & Usage

### Step 1: Install the Procedure

```sql
@sql/01_setup/00_setup.sql
```

This creates:
- Database: `SNOWFLAKE_EXAMPLE` (if not exists)
- Schema: `SEMANTIC_ENHANCEMENTS`
- Warehouse: `SFE_ENHANCEMENT_WH` (X-SMALL, auto-suspend 60s)
- Procedure: `SFE_ENHANCE_SEMANTIC_VIEW` (Python 3.11, AI_COMPLETE, llama3.3-70b)

### Step 2: Enhance Your Semantic Views

```sql
USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;

CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'YOUR_SEMANTIC_VIEW',
    P_BUSINESS_CONTEXT_PROMPT => 'Your comprehensive business context here...'
    -- Optional: P_OUTPUT_VIEW_NAME => 'CUSTOM_NAME'
);
```

### Step 3: Compare and Use

```sql
-- Compare original vs enhanced
DESCRIBE SEMANTIC VIEW YOUR_SEMANTIC_VIEW;
DESCRIBE SEMANTIC VIEW YOUR_SEMANTIC_VIEW_ENHANCED;

-- Use whichever version works best for your needs
```

---

## Procedure Parameters

```sql
SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME STRING,          -- Required: Source semantic view name
    P_BUSINESS_CONTEXT_PROMPT STRING,   -- Required: Business context for enhancement
    P_OUTPUT_VIEW_NAME STRING,          -- Optional: Output name (default: SOURCE_NAME_ENHANCED)
    P_SCHEMA_NAME STRING,               -- Optional: Schema (default: current schema)
    P_DATABASE_NAME STRING              -- Optional: Database (default: current database)
)
```

**Returns**: Success message with count of enhanced dimensions/facts, or error details with generated DDL for debugging.

---

## Writing Effective Business Context Prompts

Your business context prompt is applied to **ALL** dimensions and facts in the semantic view. Cortex AI intelligently extracts relevant information for each field.

### ✅ Good Prompt Structure

```sql
P_BUSINESS_CONTEXT_PROMPT => '
E-commerce order fulfillment system for retail operations.

ORDER STATUS CODES:
- F=Fulfilled: Shipped to customer, counts toward revenue
- O=Open: Awaiting payment, can be cancelled
- P=Processing: In warehouse, being packed

PRIORITY LEVELS:
- 1-URGENT: VIP customers, 24-hour SLA, VP approval if >$50K
- 2-HIGH: Premium customers, 48-hour SLA  
- 3-MEDIUM: Standard customers, 5-day SLA

EMPLOYEE CODES:
- Format: Clerk#NNNNNN (6-digit employee ID)
- Used for commission calculation
- Monthly quota tracking per clerk

BUSINESS RULES:
- Only fulfilled orders count toward revenue
- Orders >$100K trigger fraud screening
- Shipping costs vary by priority level
'
```

### ✅ What to Include

1. **Code Definitions**: Explain abbreviations and codes (F=Fulfilled, O=Open)
2. **Business Rules**: Important constraints and logic
3. **Domain Context**: Industry-specific terminology
4. **Relationships**: How fields relate to business processes
5. **Thresholds**: Important numeric boundaries ($50K, $100K)

### ❌ What to Avoid

- Vague descriptions: "Various status codes"
- Missing definitions: Not explaining what "F" means
- Too brief: "Order system" (not enough context)
- Too technical: SQL implementation details instead of business meaning

---

## Examples

### Example 1: E-Commerce Orders

```sql
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'ORDERS_SV',
    P_BUSINESS_CONTEXT_PROMPT => 
'E-commerce order fulfillment system. 
Status codes: F=Fulfilled (shipped), O=Open (awaiting payment), P=Processing (warehouse). 
Priority levels: 1-URGENT (VIP, 24hr SLA), 2-HIGH (48hr), 3-MEDIUM (5 day). 
Clerk codes are employee IDs for commission tracking. 
Only fulfilled orders count toward revenue targets.'
);
```

**Result**: All dimensions/facts get relevant context from the prompt.

### Example 2: Healthcare Claims

```sql
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'CLAIMS_SV',
    P_BUSINESS_CONTEXT_PROMPT => 
'Medical claims processing system. 
ICD codes follow ICD-10 standard for diagnoses. 
CPT codes identify medical procedures. 
Claim status: S=Submitted, P=Processed, A=Approved, D=Denied. 
Approved claims proceed to payment processing. 
All claims must meet regulatory compliance requirements.'
);
```

### Example 3: Financial Transactions

```sql
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'TRANSACTIONS_SV',
    P_BUSINESS_CONTEXT_PROMPT => 
'Financial transaction data subject to SOX compliance. 
Transaction types: D=Deposit, W=Withdrawal, T=Transfer. 
Amounts over $10K trigger AML reporting requirements. 
All transactions must maintain audit trail for 7 years. 
PCI-DSS compliance required for payment card data.'
);
```

---

## Use Cases

### 1. **Improve Cortex Analyst Accuracy**
Better descriptions = better AI query understanding = more accurate results

### 2. **Onboard New Team Members**
Enhanced descriptions document business logic directly in the semantic layer

### 3. **Standardize Terminology**
Apply consistent business definitions across all semantic views

### 4. **Document Domain Knowledge**
Capture tribal knowledge about codes, abbreviations, and business rules

### 5. **Regulatory Compliance**
Document compliance requirements and data governance policies

---

## Advanced Usage

### Enhance Multiple Related Views

```sql
-- Define context once, use for multiple views
SET business_context = 'Order fulfillment system. F=Fulfilled, O=Open, P=Processing...';

CALL SFE_ENHANCE_SEMANTIC_VIEW('ORDERS_SV', $business_context);
CALL SFE_ENHANCE_SEMANTIC_VIEW('ORDER_DETAILS_SV', $business_context);
CALL SFE_ENHANCE_SEMANTIC_VIEW('ORDER_HISTORY_SV', $business_context);
```

### Custom Output Names

```sql
-- Create multiple versions with different context levels
CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'ORDERS_SV',
    P_BUSINESS_CONTEXT_PROMPT => 'Basic order system context...',
    P_OUTPUT_VIEW_NAME => 'ORDERS_SV_BASIC'
);

CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'ORDERS_SV',
    P_BUSINESS_CONTEXT_PROMPT => 'Detailed regulatory and compliance context...',
    P_OUTPUT_VIEW_NAME => 'ORDERS_SV_COMPLIANCE'
);
```

### Iterative Refinement

```sql
-- Try first enhancement
CALL SFE_ENHANCE_SEMANTIC_VIEW('ORDERS_SV', 'Basic context...');
DESCRIBE SEMANTIC VIEW ORDERS_SV_ENHANCED;

-- Not satisfied? Drop and try with better context
DROP SEMANTIC VIEW ORDERS_SV_ENHANCED;
CALL SFE_ENHANCE_SEMANTIC_VIEW('ORDERS_SV', 'More detailed context...');
```

---

## Cost & Performance

### Cortex AI Model: `llama3.3-70b`

- **Latest generation** Llama model with improved reasoning
- **Optimal balance** of quality and cost
- **~5x cheaper** than mistral-large2
- **High-quality** business descriptions with better context understanding

### Estimated Demo Costs

#### Edition Requirement
- **Minimum Edition:** Standard ($2/credit) or higher
- **Cortex AI:** Included in Standard+ editions

#### One-Time Setup Costs
| Component | Size/Usage | Estimated Credits | Cost |
|-----------|------------|-------------------|------|
| Setup SQL execution | X-SMALL, ~1 min | < 0.002 | < $0.01 |
| Example creation | X-SMALL, ~2 min | < 0.004 | < $0.01 |
| **Total Setup** | | **~0.006** | **~$0.01** |

#### Per-Enhancement Costs
| Component | Details | Estimated Cost |
|-----------|---------|----------------|
| Cortex AI (llama3.3-70b) | ~10 tokens/dimension | $0.001-0.002/dimension |
| Warehouse compute | X-SMALL, ~30 sec | < $0.01 |
| **Per semantic view (10 dimensions)** | | **~$0.02** |
| **Per semantic view (50 dimensions)** | | **~$0.10** |
| **Per semantic view (100 dimensions)** | | **~$0.20** |

#### Monthly Ongoing Costs
- **Storage:** $0 (semantic views are metadata only)
- **Idle warehouse:** $0 (auto-suspends after 60 seconds)
- **Monthly total if unused:** $0

#### Cost Justification
- **ROI:** Improved semantic layer quality → Better Cortex Analyst accuracy
- **Alternative:** Manual documentation (hours of work vs. pennies)
- **Bottom line:** Negligible cost for significant improvement in semantic layer quality

---

## Troubleshooting

### Error: "Semantic view not found"
**Cause**: Source view doesn't exist or wrong schema/database  
**Solution**: Verify with `SHOW SEMANTIC VIEWS` and check spelling

### Error: "Could not get DDL"
**Cause**: Insufficient permissions or view is corrupted  
**Solution**: Ensure you have SELECT privilege on the view

### Error: "Table 'X' does not exist"
**Cause**: GET_DDL returned unqualified table names and regex fix failed  
**Solution**: Check the generated DDL in error message, may need manual fix

### Error: "Cortex function not available"
**Cause**: Cortex not enabled in your account  
**Solution**: Contact Snowflake support to enable Cortex features

### Enhancement doesn't make sense
**Cause**: Business context prompt is too vague or missing key information  
**Solution**: Refine your prompt with more specific definitions and examples

---

## Technical Details

### How DDL Transformation Works

1. **Extract DDL**: `GET_DDL('SEMANTIC_VIEW', 'schema.view', TRUE)`
2. **Parse Metadata**: `DESCRIBE SEMANTIC VIEW` for dimensions, facts, and base tables
3. **Fix Table References**: Ensure fully qualified table names (e.g., `DB.SCHEMA.TABLE`)
4. **Enhance Comments**: Call Cortex for each dimension/fact
5. **Update DDL**: Regex replace old comments with enhanced ones
6. **Create View**: Execute modified DDL with new view name

### Limitations

- **ALTER not supported**: Snowflake doesn't support `ALTER SEMANTIC VIEW ... ALTER DIMENSION ... SET COMMENT`
- **Must recreate**: Only way to modify comments is to create a new view
- **Original preserved**: This is actually a benefit - safe to experiment

### String Escaping

The procedure handles:
- Single quotes in prompts and responses
- Newlines and whitespace in AI-generated text
- Special characters in business context

---

## File Structure

```
better-descriptions/
├── README.md                      # This file
├── deploy_all.sql                 # One-script deployment (Snowsight copy/paste)
├── diagrams/                      # Architecture diagrams (MANDATORY)
│   ├── data-model.md             # Semantic view metadata structure
│   ├── data-flow.md              # Data flow through enhancement system
│   ├── network-flow.md           # Network architecture
│   └── auth-flow.md              # Authentication & authorization
├── docs/                          # User documentation
│   ├── 01-QUICK-START.md         # Setup and usage guide
│   └── 02-TROUBLESHOOTING.md     # Common issues and solutions
└── sql/                           # SQL scripts (for manual execution)
    ├── 01_setup/
    │   └── 00_setup.sql          # Creates enhancement procedure
    ├── 02_examples/
    │   └── 01_example_usage.sql  # Working examples with TPCH data
    └── 99_cleanup/
        └── teardown_all.sql      # Removes all created objects
```

---

## Cleanup

To remove all created objects:

```sql
@sql/99_cleanup/teardown_all.sql
```

This drops:
- Schema `SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS` (CASCADE)
- All semantic views in the schema
- The enhancement procedure
- The dedicated warehouse `SFE_ENHANCEMENT_WH`

**Preserved**:
- `SNOWFLAKE_EXAMPLE` database (may contain other demo projects)

---

## Contributing

Suggestions and improvements welcome! This tool was built to solve a real problem: making semantic views more useful for Cortex Analyst by adding rich business context to dimension and fact descriptions.

---

## Key Takeaways

1. ✅ **Creates enhanced copies** - Original views stay safe
2. ✅ **One procedure, one call** - Simple API
3. ✅ **Cortex-powered** - AI understands your business context
4. ✅ **Production-ready** - Handles errors, escaping, edge cases
5. ✅ **Cost-effective** - Pennies per semantic view
6. ✅ **Flexible** - Iterative refinement supported

---

## Resources

- [Snowflake Semantic Views Documentation](https://docs.snowflake.com/en/user-guide/views-semantic)
- [Cortex COMPLETE Function](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions)
- [GET_DDL Function](https://docs.snowflake.com/en/sql-reference/functions/get_ddl)
- [DESCRIBE SEMANTIC VIEW](https://docs.snowflake.com/en/sql-reference/sql/desc-semantic-view)

---

## License

This tool is provided as-is for use with Snowflake. Modify and adapt as needed for your organization.
