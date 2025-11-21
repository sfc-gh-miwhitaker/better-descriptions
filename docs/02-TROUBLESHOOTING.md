# Troubleshooting Guide

Common issues and solutions for the Semantic View Enhancement Tool.

---

## Installation Issues

### ❌ "Database SNOWFLAKE_EXAMPLE does not exist"

**Cause**: Insufficient permissions to create database

**Solutions**:
1. Request database creation privileges from your admin
2. OR: Modify `sql/00_setup.sql` to use an existing database:
   ```sql
   -- Change line 15 to your database
   USE DATABASE YOUR_EXISTING_DATABASE;
   CREATE SCHEMA IF NOT EXISTS YOUR_EXISTING_DATABASE.SEMANTIC_ENHANCEMENTS;
   ```

### ❌ "Database SNOWFLAKE_SAMPLE_DATA does not exist"

**Cause**: Sample data not mounted in your account

**Solution**: Mount the Snowflake sample data share:
```sql
-- Run as ACCOUNTADMIN or similar role
SHOW SHARES LIKE 'SAMPLE_DATA';

CREATE DATABASE SNOWFLAKE_SAMPLE_DATA 
  FROM SHARE SFSALESSHARED.SFC_SAMPLES_VA2.SAMPLE_DATA;

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO PUBLIC;
```

This sample data is automatically available to all Snowflake customers in your deployment/region.

**Alternative**: Skip the examples and use your own semantic views instead.

### ❌ "Warehouse SFE_ENHANCEMENT_WH does not exist or not authorized"

**Cause**: The setup script didn't run successfully or warehouse creation failed

**Solutions**:
1. Run the setup script to create the warehouse:
   ```sql
   @sql/01_setup/00_setup.sql
   ```
2. OR: Manually create the warehouse:
   ```sql
   CREATE WAREHOUSE SFE_ENHANCEMENT_WH
     WAREHOUSE_SIZE = 'X-SMALL'
     AUTO_SUSPEND = 60
     AUTO_RESUME = TRUE
     COMMENT = 'DEMO: better-descriptions';
   ```
3. OR: Modify SQL files to use your existing warehouse:
   ```sql
   -- Change to your warehouse name
   USE WAREHOUSE YOUR_WAREHOUSE_NAME;
   ```

### ❌ "Insufficient privileges to create procedure"

**Cause**: Role lacks CREATE PROCEDURE privilege

**Solution**: Request privilege from admin:
```sql
GRANT CREATE PROCEDURE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS 
  TO ROLE YOUR_ROLE;
```

---

## Runtime Errors

### ❌ "Semantic view not found"

**Full Error**: `Error: Could not describe semantic view. Error: ... object does not exist`

**Causes & Solutions**:

1. **Wrong view name**
   - Check spelling: `SHOW SEMANTIC VIEWS;`
   - Verify case: Snowflake is case-sensitive with quoted identifiers

2. **Wrong schema/database**
   - Specify full path:
     ```sql
     CALL SFE_ENHANCE_SEMANTIC_VIEW(
         P_SOURCE_VIEW_NAME => 'VIEW_NAME',
         P_BUSINESS_CONTEXT_PROMPT => '...',
         P_SCHEMA_NAME => 'YOUR_SCHEMA',
         P_DATABASE_NAME => 'YOUR_DATABASE'
     );
     ```

3. **Not a semantic view**
   - Verify it's a semantic view, not a regular view:
     ```sql
     SHOW SEMANTIC VIEWS LIKE 'YOUR_VIEW%';
     ```

### ❌ "Could not get DDL"

**Full Error**: `Error: Could not get DDL for ... `

**Causes & Solutions**:

1. **Insufficient SELECT privilege**
   ```sql
   GRANT SELECT ON SEMANTIC VIEW your_schema.your_view TO ROLE YOUR_ROLE;
   ```

2. **View is corrupted or deprecated**
   - Try recreating the view from scratch
   - Check if it's using deprecated syntax

### ❌ "Table 'X' does not exist or not authorized"

**Full Error**: `Error creating view: ... Table 'ORDERS' does not exist`

**Cause**: The generated DDL has unqualified table references

**Solution**: This should be auto-fixed by the procedure, but if it fails:

1. Check the generated DDL in the error message
2. Look for table names without database.schema prefix
3. The procedure attempts to fix this automatically - if it fails, there may be a regex edge case

**Workaround**: Manually add the database/schema prefix and create the view yourself:
```sql
-- Copy the DDL from error message
-- Find: orders AS ORDERS
-- Replace: orders AS YOUR_DATABASE.YOUR_SCHEMA.ORDERS
```

### ❌ "Cortex function not available"

**Full Error**: `... SNOWFLAKE.CORTEX.COMPLETE ... does not exist`

**Cause**: Cortex features not enabled in your Snowflake account

**Solution**: Contact Snowflake support to enable Cortex features for your account

### ❌ "Token limit exceeded"

**Full Error**: `... token limit ... exceeded`

**Cause**: Business context prompt + all dimension prompts exceed Cortex token limit

**Solutions**:
1. **Shorten your prompt**: Remove unnecessary details
2. **Split into multiple calls**: Enhance view in batches (not directly supported - would need modification)
3. **Use smaller model**: Modify procedure to use `llama3.1-8b` (less context window)

---

## Result Quality Issues

### ⚠️ "Descriptions don't make sense"

**Symptom**: AI-generated descriptions are generic or off-topic

**Causes & Solutions**:

1. **Vague business context**
   - ❌ Bad: "Order system with various statuses"
   - ✅ Good: "Order fulfillment system. Status codes: F=Fulfilled (shipped to customer), O=Open (awaiting payment confirmation), P=Processing (in warehouse being picked and packed)"

2. **Missing code definitions**
   - Always define abbreviations and codes
   - Include what each code means in business terms

3. **No business rules**
   - Explain WHY fields matter
   - Include thresholds, SLAs, approval requirements

**Fix**: Drop the enhanced view and re-run with better context:
```sql
DROP SEMANTIC VIEW YOUR_VIEW_ENHANCED;

CALL SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME => 'YOUR_VIEW',
    P_BUSINESS_CONTEXT_PROMPT => 'More detailed and specific context...'
);
```

### ⚠️ "Some descriptions are too long"

**Symptom**: Descriptions are truncated with "..."

**Cause**: The procedure limits descriptions to 200 characters

**Solution**: Modify the procedure if you need longer descriptions:
```sql
-- In 00_setup.sql, find and change:
if len(enhanced_desc) > 200:
    enhanced_desc = enhanced_desc[:197] + '...'

-- Change to:
if len(enhanced_desc) > 500:  -- Or your desired length
    enhanced_desc = enhanced_desc[:497] + '...'
```

Then re-run `@sql/00_setup.sql` to update the procedure.

### ⚠️ "Descriptions are inconsistent"

**Symptom**: Some dimensions have great descriptions, others are still generic

**Cause**: Business context doesn't cover all fields equally

**Solution**: Expand your prompt to include context for ALL dimensions:
- List every code/abbreviation used
- Explain every field's business purpose
- Include relationships between fields

---

## Performance Issues

### ⏱️ "Takes too long to run"

**Symptom**: Procedure runs for several minutes

**Causes**:

1. **Large semantic view** (50+ dimensions/facts)
   - Expected: ~2-4 seconds per dimension/fact
   - 50 fields = ~2-3 minutes

2. **Cortex API slowness**
   - Varies by region and load
   - Usually resolves itself

**Solutions**:
- **Be patient**: This is normal for large views
- **Run during off-peak**: Cortex might be faster
- **Use smaller model**: Modify to use `llama3.1-8b` (faster, lower quality)

### 💰 "Costs too much"

**Symptom**: Concerned about Cortex costs

**Reality Check**:
- 10 dimensions/facts: <$0.02
- 100 dimensions/facts: <$0.20
- 1000 dimensions/facts: <$2.00

**If still concerned**:
1. **Switch to cheaper model**: Use `llama3.1-8b` instead of `llama3.1-70b`
2. **Batch your enhancements**: Don't re-run unnecessarily
3. **Cache results**: Save enhanced views, don't recreate repeatedly

---

## Edge Cases

### 🔧 "View with special characters in names"

**Issue**: Dimension names with spaces, quotes, or special characters

**Solution**: Snowflake handles this internally - should work fine. If not, use standard naming (no spaces/special chars).

### 🔧 "Multi-table semantic view fails"

**Issue**: Semantic view with multiple tables and relationships fails to create

**Cause**: Table reference fixing might miss some tables

**Debug**:
1. Look at the generated DDL in error message
2. Check if ALL tables have fully qualified names
3. Manually fix any missing qualifications

**Report**: If you encounter this, it's likely a regex edge case in the procedure

### 🔧 "View with metrics fails"

**Issue**: Semantic views with METRICS (not just dimensions/facts) might have issues

**Status**: The procedure focuses on dimensions and facts. Metrics are preserved but not enhanced.

**Workaround**: Manually enhance metric descriptions in the original CREATE statement

---

## Getting Detailed Debug Information

### Enable Verbose Error Output

The procedure already returns detailed errors. To see more:

1. **Check the full error message**: Don't just read the first line
2. **Review generated DDL**: Error messages include DDL preview
3. **Test DDL manually**: Copy the generated DDL and try running it yourself

### Manual Debug Steps

```sql
-- 1. Verify source view exists
DESCRIBE SEMANTIC VIEW YOUR_VIEW;

-- 2. Check you can get DDL
SELECT GET_DDL('SEMANTIC_VIEW', 'YOUR_SCHEMA.YOUR_VIEW', TRUE);

-- 3. Test Cortex access
SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b', 'Test prompt');

-- 4. Check permissions
SHOW GRANTS ON SEMANTIC VIEW YOUR_SCHEMA.YOUR_VIEW;
```

---

## Common Workarounds

### Workaround: Can't modify procedure

If you can't recreate the procedure but need to change behavior:

**Option 1**: Create your own wrapper procedure  
**Option 2**: Use the procedure as-is and manually fix results  
**Option 3**: Copy sql/00_setup.sql to your own schema with modifications

### Workaround: Need to enhance many views

Create a script:
```sql
-- enhance_all_views.sql
CALL SFE_ENHANCE_SEMANTIC_VIEW('VIEW1', :shared_context);
CALL SFE_ENHANCE_SEMANTIC_VIEW('VIEW2', :shared_context);
CALL SFE_ENHANCE_SEMANTIC_VIEW('VIEW3', :shared_context);
-- etc.
```

### Workaround: Want different AI model

Modify `sql/00_setup.sql` line 153:
```python
# Change from:
cortex_sql = f"SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b', '{prompt_escaped}')"

# To:
cortex_sql = f"SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', '{prompt_escaped}')"
# Or: 'llama3.1-8b', 'mixtral-8x7b', etc.
```

---

## Still Stuck?

### Before Asking for Help

1. ✅ Run the examples (`@sql/01_example_usage.sql`) - do they work?
2. ✅ Check all error messages carefully
3. ✅ Verify your Snowflake account has Cortex enabled
4. ✅ Confirm you have necessary privileges
5. ✅ Try with a simpler semantic view first

### Information to Provide

When seeking help, include:
- Full error message (not just first line)
- The exact CALL statement you ran
- Generated DDL (if shown in error)
- Snowflake region and account type
- Whether examples work or not

---

## Error Message Reference

| Error Contains | Likely Cause | Fix |
|----------------|--------------|-----|
| "does not exist" | Missing object | Check spelling, schema, database |
| "not authorized" | Permission issue | Request privileges from admin |
| "CORTEX.COMPLETE" | Cortex not enabled | Enable Cortex in account |
| "token limit" | Prompt too long | Shorten business context |
| "DDL" | View creation failed | Review generated DDL |
| "Table 'X'" | Unqualified table name | Should auto-fix; check DDL |
| "syntax error" | Invalid SQL generated | Review DDL for special chars |

---

## Prevention Tips

### ✅ Best Practices to Avoid Issues

1. **Start with examples**: Always test with provided examples first
2. **Simple prompts**: Start simple, add complexity gradually
3. **Test incrementally**: Enhance one view at a time initially
4. **Save successful prompts**: Document what works
5. **Version control**: Keep enhanced views in source control
6. **Monitor costs**: Check Cortex usage in account dashboard

### ✅ Pre-Flight Checklist

Before enhancing production views:

- [ ] Examples work successfully
- [ ] Source view exists and is accessible  
- [ ] Business context prompt is comprehensive
- [ ] Tested with a small view first
- [ ] Have rollback plan (original view preserved)
- [ ] Documented the business context used

---

**Most issues are quickly resolved by checking permissions, fixing typos, or improving the business context prompt. Don't hesitate to iterate!**

