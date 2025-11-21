/*******************************************************************************
 * DEMO PROJECT: better-descriptions
 * Script: Setup - Create Enhancement Procedure
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * Author: SE Community | Expires: 2025-12-21
 * 
 * PURPOSE:
 *   Create an enhanced copy of a semantic view with AI-improved dimension
 *   and fact descriptions using Snowflake Cortex AI
 * 
 * HOW IT WORKS:
 *   1. Uses GET_DDL to retrieve the source semantic view definition
 *   2. Enhances all dimension/fact comments using Cortex AI with business context
 *   3. Creates a new semantic view with enhanced comments
 *   4. Original semantic view remains unchanged - a new enhanced copy is created
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE database (if not exists)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS schema
 *   - SFE_ENHANCEMENT_WH warehouse (X-SMALL, 60s auto-suspend)
 *   - SFE_ENHANCE_SEMANTIC_VIEW stored procedure (Python 3.11, AI_COMPLETE, llama3.3-70b)
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
-- Setup Script
-- ═══════════════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;
USE SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_ENHANCEMENTS;

-- Create dedicated demo warehouse with optimal settings
CREATE WAREHOUSE IF NOT EXISTS SFE_ENHANCEMENT_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'DEMO: better-descriptions - Dedicated warehouse for semantic view enhancement workload';

USE WAREHOUSE SFE_ENHANCEMENT_WH;

-- Create the enhancement stored procedure
CREATE OR REPLACE PROCEDURE SFE_ENHANCE_SEMANTIC_VIEW(
    P_SOURCE_VIEW_NAME STRING,
    P_BUSINESS_CONTEXT_PROMPT STRING,
    P_OUTPUT_VIEW_NAME STRING DEFAULT NULL,
    P_SCHEMA_NAME STRING DEFAULT CURRENT_SCHEMA(),
    P_DATABASE_NAME STRING DEFAULT CURRENT_DATABASE()
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'enhance_view'
AS
$$
import re

def enhance_view(session, p_source_view_name, p_business_context_prompt, p_output_view_name, p_schema_name, p_database_name):
    """
    Creates an enhanced copy of a semantic view with AI-improved dimension/fact comments.
    
    Since ALTER SEMANTIC VIEW doesn't support modifying dimension/fact comments,
    this procedure:
    1. Gets the DDL of the source semantic view
    2. Enhances all dimension/fact comments using Cortex AI
    3. Recreates the view with a new name and enhanced comments
    """
    
    # Determine output view name
    if not p_output_view_name:
        p_output_view_name = f"{p_source_view_name}_ENHANCED"
    
    # Construct fully qualified view names
    source_view_full = f"{p_schema_name}.{p_source_view_name}"
    output_view_full = f"{p_schema_name}.{p_output_view_name}"
    
    # Use DESCRIBE SEMANTIC VIEW to get complete structure
    try:
        describe_result = session.sql(f"DESCRIBE SEMANTIC VIEW {p_database_name}.{source_view_full}").collect()
    except Exception as e:
        return f"Error: Could not describe semantic view. Error: {str(e)}"
    
    # Get the DDL of the source semantic view using correct syntax
    try:
        ddl_result = session.sql(f"SELECT GET_DDL('SEMANTIC_VIEW', '{source_view_full}', TRUE)").collect()
        source_ddl = ddl_result[0][0]
    except Exception as e:
        return f"Error: Could not get DDL for {source_view_full}. Error: {str(e)}"
    
    # Parse DESCRIBE output to get source table mappings
    # TABLE rows have BASE_TABLE_DATABASE_NAME, BASE_TABLE_SCHEMA_NAME, BASE_TABLE_NAME
    table_info = {}
    for row in describe_result:
        if row['object_kind'] == 'TABLE':
            table_alias = row['object_name']
            if table_alias not in table_info:
                table_info[table_alias] = {}
            
            if row['property'] == 'BASE_TABLE_DATABASE_NAME':
                table_info[table_alias]['database'] = row['property_value']
            elif row['property'] == 'BASE_TABLE_SCHEMA_NAME':
                table_info[table_alias]['schema'] = row['property_value']
            elif row['property'] == 'BASE_TABLE_NAME':
                table_info[table_alias]['table'] = row['property_value']
    
    # Build fully qualified table names
    table_mappings = {}
    for alias, info in table_info.items():
        if 'database' in info and 'schema' in info and 'table' in info:
            table_mappings[alias] = f"{info['database']}.{info['schema']}.{info['table']}"
    
    # Extract unique dimensions and facts with their current comments
    dimensions = {}
    for row in describe_result:
        obj_kind = row['object_kind']
        obj_name = row['object_name']
        prop = row['property']
        prop_value = row['property_value']
        
        # We want DIMENSION and FACT objects only
        if obj_kind in ['DIMENSION', 'FACT'] and obj_name:
            if obj_name not in dimensions:
                dimensions[obj_name] = {
                    'kind': obj_kind,
                    'comment': '',
                    'data_type': '',
                    'expression': ''
                }
            
            # Capture properties
            if prop == 'COMMENT' and prop_value:
                dimensions[obj_name]['comment'] = prop_value
            elif prop == 'DATA_TYPE' and prop_value:
                dimensions[obj_name]['data_type'] = prop_value
            elif prop == 'EXPRESSION' and prop_value:
                dimensions[obj_name]['expression'] = prop_value
    
    if not dimensions:
        return f"No dimensions or facts found in {p_source_view_name}"
    
    # Generate enhanced comments for each dimension/fact
    enhanced_comments = {}
    enhanced_count = 0
    errors = []
    
    for dim_name, dim_info in dimensions.items():
        try:
            # Build prompt for Cortex
            current_desc_text = f"CURRENT DESCRIPTION: {dim_info['comment']}" if dim_info['comment'] else "CURRENT DESCRIPTION: None"
            data_type_text = f"DATA TYPE: {dim_info['data_type']}" if dim_info['data_type'] else ""
            
            prompt = f"""You are enhancing a Snowflake semantic view {dim_info['kind'].lower()} description for Cortex Analyst.

{dim_info['kind']}: {dim_name}
{data_type_text}
{current_desc_text}

ADDITIONAL BUSINESS CONTEXT:
{p_business_context_prompt}

Task: Create a concise, enhanced description (max 150 characters) that:
1. Incorporates relevant parts of the additional business context
2. Preserves useful information from the current description if any
3. Is optimized for AI query understanding
4. Focuses on business meaning

Output ONLY the enhanced description text, no formatting or quotes."""
            
            # Escape single quotes for SQL (double them for Snowflake)
            prompt_escaped = prompt.replace("'", "''")
            
            # Call Cortex AI to enhance (using latest AI_COMPLETE function and llama3.3-70b model)
            cortex_sql = f"SELECT AI_COMPLETE('llama3.3-70b', '{prompt_escaped}')"
            cortex_result = session.sql(cortex_sql).collect()
            enhanced_desc = cortex_result[0][0].strip()
            
            # Clean up the response - remove quotes if Cortex added them
            if enhanced_desc.startswith('"') and enhanced_desc.endswith('"'):
                enhanced_desc = enhanced_desc[1:-1]
            if enhanced_desc.startswith("'") and enhanced_desc.endswith("'"):
                enhanced_desc = enhanced_desc[1:-1]
            
            # Remove newlines and extra whitespace that could break SQL
            enhanced_desc = ' '.join(enhanced_desc.split())
            
            # Limit length to avoid very long comments
            if len(enhanced_desc) > 200:
                enhanced_desc = enhanced_desc[:197] + '...'
            
            # Store the enhanced comment
            enhanced_comments[dim_name] = enhanced_desc
            enhanced_count += 1
            
        except Exception as e:
            errors.append(f"{dim_name}: {str(e)[:150]}")
            # Keep original comment if enhancement fails
            enhanced_comments[dim_name] = dim_info['comment']
            continue
    
    # Update the DDL with enhanced comments and change the view name
    new_ddl = source_ddl
    
    # Replace the view name in the DDL
    # The DDL contains the fully qualified name: DATABASE.SCHEMA.VIEW
    # We need to replace the entire qualified name
    source_fqn = f"{p_database_name}.{source_view_full}"
    output_fqn = f"{p_database_name}.{output_view_full}"
    
    # Pattern: create or replace semantic view DATABASE.SCHEMA.VIEWNAME  
    new_ddl = re.sub(
        rf'(create\s+or\s+replace\s+semantic\s+view\s+){re.escape(source_fqn)}',
        rf'\1{output_fqn}',
        new_ddl,
        flags=re.IGNORECASE
    )
    
    # Fix table references - GET_DDL may not fully qualify them in TABLES clause
    # If no mappings found, return error with DDL for debugging
    if not table_mappings:
        return f"Error: No table mappings found. Cannot determine source tables. DDL: {source_ddl[:1000]}"
    
    # The DDL can have different formats:
    # 1. TABLEALIAS as UNQUALIFIED_TABLE primary key ...
    # 2. TABLEALIAS primary key ... (no AS clause)
    # We need to handle both cases
    for table_alias, source_table in table_mappings.items():
        # Case 1: TABLEALIAS as SOMETABLE (where SOMETABLE is not fully qualified)
        # Replace with: TABLEALIAS as FULL.QUALIFIED.NAME
        pattern1 = rf'\b{re.escape(table_alias)}\s+as\s+(\w+)(?!\.)' 
        replacement1 = rf'{table_alias} as {source_table}'
        new_ddl = re.sub(pattern1, replacement1, new_ddl, flags=re.IGNORECASE)
        
        # Case 2: TABLEALIAS primary key (no AS clause at all)
        # Replace with: TABLEALIAS as FULL.QUALIFIED.NAME primary key
        pattern2 = rf'\b{re.escape(table_alias)}\s+(primary\s+key|comment|unique)'
        replacement2 = rf'{table_alias} as {source_table} \1'
        new_ddl = re.sub(pattern2, replacement2, new_ddl, flags=re.IGNORECASE)
    
    # Replace each comment in the DDL
    for dim_name, enhanced_comment in enhanced_comments.items():
        # Escape single quotes for SQL
        safe_comment = enhanced_comment.replace("'", "''")
        
        # Pattern: dimension_name AS column_name COMMENT = 'old comment'
        # This pattern handles: tablealias.dimension_name AS alias_name COMMENT = 'text'
        pattern = rf"(\w+\.{re.escape(dim_name)}\s+AS\s+\w+\s+COMMENT\s*=\s*)'[^']*'"
        replacement = rf"\1'{safe_comment}'"
        new_ddl = re.sub(pattern, replacement, new_ddl, flags=re.IGNORECASE)
    
    # Execute the new DDL to create the enhanced semantic view
    try:
        session.sql(new_ddl).collect()
        result_msg = f"Successfully created {p_output_view_name} with {enhanced_count} enhanced dimension/fact comments"
    except Exception as create_error:
        # If creation fails, return the DDL for manual review
        error_details = f"Error creating view: {str(create_error)}"
        # Show first 2000 chars of DDL for debugging
        ddl_preview = new_ddl[:2000] if len(new_ddl) > 2000 else new_ddl
        return f"{error_details}\n\nGenerated DDL:\n{ddl_preview}"
    
    if errors:
        result_msg += f". Note: {len(errors)} dimension(s) had enhancement errors and kept original comments."
    
    return result_msg
$$;

-- SETUP COMPLETE
-- The enhancement procedure is ready to use
-- 
-- Creates an enhanced copy of a semantic view with AI-improved dimension/fact comments
-- 
-- Usage:
--   CALL SFE_ENHANCE_SEMANTIC_VIEW(
--     P_SOURCE_VIEW_NAME => 'YOUR_VIEW',
--     P_BUSINESS_CONTEXT_PROMPT => 'Your business context...',
--     P_OUTPUT_VIEW_NAME => 'YOUR_VIEW_ENHANCED'  -- Optional, defaults to SOURCE_NAME_ENHANCED
--   );
--
-- The original semantic view remains unchanged
-- A new semantic view is created with enhanced descriptions
