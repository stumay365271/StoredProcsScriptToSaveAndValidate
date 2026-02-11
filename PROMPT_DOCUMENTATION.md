# SQL Server Stored Procedure Export & Validation - Prompt Documentation

## Project Overview
During **database conversions and migrations**, the source databases containing the original stored procedures are often overwritten or replaced. Our team needed an automated solution to export stored procedures from SQL Server databases and validate them *before* the conversion process overwrites them. This preserves a complete inventory of our database objects, ensures quality standards are maintained in the new environment, and provides a checkpoint for validating that all procedures meet our business rules. The solution needed to:
- Extract stored procedures with consistent, clean formatting
- Validate compliance with naming conventions and business rules
- Generate reports of any violations
- Work efficiently to export and validate hundreds of procedures before database transition

---

## Prompt 1: Combined Export and Validation Solution
**Prompt:**
> "Create a master PowerShell script that handles the complete workflow for SQL Server stored procedures:
> 1. Export stored procedures from a database to individual .sql files
> 2. Validate the exported procedures against business rules
> 3. Generate a validation report
>
> The script should:
> - Accept server, database, schema, and naming pattern as configuration
> - Connect to SQL Server using Windows authentication
> - Filter procedures by schema and naming pattern
> - Clean up exported SQL (remove SET statements, normalize CREATE statements)
> - Check that procedures have RecordStatus=0 checks
> - Verify procedure names follow naming convention [SCHEMA.]<ProcType>_
> - Write validation results to a file
> - Handle errors gracefully"

**Result:**
- Unified ProcessAndValidate.ps1 script combining export and validation
- SMO (SQL Server Management Objects) for database operations
- Invoke-Sqlcmd for secure queries and validation
- Normalize-ProcScript function for SQL cleanup
- Two-phase workflow with clear section separation
- Comprehensive error handling throughout

---

## Prompt 2: Interactive Configuration with User Prompts
**Prompt:**
> "The script has hardcoded values scattered throughout. Replace all hardcoded configuration with interactive prompts:
> - SQL Server instance name
> - Database name
> - Schema name
> - Stored procedure name pattern (e.g., RptSrc_*)
> - Output folder path
>
> Make the script runnable from any directory without modifying the code."

**Result:**
- Five Read-Host prompts at script start
- User-friendly prompt text with examples
- No hardcoded paths or server names
- Output path prompt without defaults (user specifies destination)
- All configuration captured before processing begins
- Script works from any directory

---

## Prompt 3: Database Validation and Connection Security
**Prompt:**
> "Before exporting, verify the target database exists. Also ensure secure connections:
> - Query the master database to confirm target database availability
> - Show available databases if target not found
> - Use encrypted connections with certificate trust
> - Implement Windows authentication"

**Result:**
- Added Invoke-Sqlcmd query to sys.databases with state filter
- Case-insensitive database name matching
- Lists available databases on validation failure
- LoginSecure enabled for Windows authentication
> - EncryptConnection enabled for secure transport
- TrustServerCertificate for encrypted connections
- Early exit on database not found

---

## Prompt 4: Stored Procedure Export Phase
**Prompt:**
> "Implement the export phase that:
> - Queries stored procedures with dynamic schema and name pattern filtering
> - Uses SMO Scripter for reliable procedure extraction
> - Normalizes SQL output consistently
> - Exports each procedure to a separate file
> - Provides progress feedback
> - Handles individual failures without stopping"

**Result:**
- Dynamic SQL query filtering by schema and name pattern
- SMO Scripter with optimized options (SchemaQualify, NoCollation, NoFileGroup)
- Normalize-ProcScript function using regex to clean SQL
- Converts all procedures to CREATE OR ALTER PROC format (handles CREATE, ALTER, and variations)
- Files saved with Schema.ProcName.sql naming convention
- UTF8 encoding without BOM for version control
- Per-procedure try-catch for fault tolerance
- Status messages for each export

---

## Prompt 5: Validation Phase Implementation
**Prompt:**
> "After exporting, validate all procedures against business rules:
> - Rule #2: Check that procedures validate RecordStatus=0 on tables
> - Rule #3: Verify procedure names follow naming convention [SCHEMA.]<ProcType>_
>   (where SCHEMA is optional but if present must match the actual schema)
>   (ProcType can be any valid identifier followed by underscore)
> - For any violations, create detailed report
> - Write results to Validation_Results.txt"

**Result:**
- Scans all exported .sql files in output folder
- Regex-based checks for RecordStatus=0 validation
- Procedure name validation against [SCHEMA.]<ProcType>_ pattern
- Checks if schema prefix (if present) matches actual procedure schema
- Violation details captured with file and rule info
- Results aggregated and written to file
- Success message if all procedures pass validation

---

## Prompt 6: User Experience and Status Reporting
**Prompt:**
> "Improve the user experience:
> - Add clear section headers showing export vs. validation phases
> - Use color-coded output (cyan for sections, green for success)
> - Show progress during export (which procedures are being processed)
> - Provide summary statistics at the end
> - Display file paths for outputs"

**Result:**
- Color-coded Write-Host messages (Cyan headers, Green success)
- Clear section separators with === markers
- Per-procedure export status messages
- Procedure count feedback at each phase
- Final summary showing total exported and validation report path
- All output file paths displayed for user reference

---

## Prompt 7: Validate-Only Mode
**Prompt:**
> "Add ability to run validation without exporting. Create a mode selection at the start:
> - Mode 1: Export and Validate (full workflow)
> - Mode 2: Validate Only (validate existing .sql files without re-exporting)
>
> This allows users to:
> - Re-validate exported files if rules change
> - Validate files from previous exports
> - Skip expensive database export if only checking compliance"

**Result:**
- Mode selection prompt at script start
- Mode 1 prompts for server/database/schema/pattern, then exports and validates
- Mode 2 only prompts for output folder, skips export, runs validation only
- Conditional execution of export section based on selected mode
- Status message indicating skipped export in mode 2

---

## Final Solution: ProcessAndValidate.ps1

### Configuration Prompts

**Initial Prompt:**
1. Operation mode (1 = Export and Validate, 2 = Validate Only)

**Mode 1 (Export and Validate) Additional Prompts:**
2. SQL Server instance name
3. Database name
4. Schema name
5. Stored procedure name pattern (e.g., RptSrc_*, *, dbo.*)

**Both Modes:**
- Output folder path (where .sql files are/will be located)

### Workflow

**Mode 1: Export and Validate**

**Phase 1: Export**
- Validates target database exists
- Connects using Windows authentication with encrypted connection
- Queries procedures matching schema and name pattern (supports wildcards: *, ALSC.*, RptSrc_*, etc.)
- Exports each procedure to individual .sql file
- Normalizes SQL formatting:
  - Removes SET ANSI_NULLS and SET QUOTED_IDENTIFIER statements
  - Removes GO statements
  - Converts all procedures to CREATE OR ALTER PROC format (handles CREATE, ALTER, or CREATE OR ALTER input)
- UTF8 encoding without BOM for clean version control

**Phase 2: Validate**
- Scans all exported .sql files in output folder
- Checks for RecordStatus=0 validation in queries (Rule #2)
- Validates procedure naming follows [SCHEMA.]<ProcType>_ convention (Rule #3)
- Flags procedures where schema prefix doesn't match actual schema
- Generates detailed violation report

**Mode 2: Validate Only**

**Validation Phase**
- Skips export entirely
- Scans existing .sql files in output folder
- Runs same validation rules as Mode 1 Phase 2
- Useful for re-validating after rule changes or checking previously exported files

**Output Files**
- Individual .sql files for each stored procedure (named: Schema.ProcName.sql)
- Validation_Results.txt containing all validation findings
- ValidationRules.txt defining business rules with instructions for adding new rules

### Business Rules

**Note:** Complete validation rule definitions and instructions for adding new rules are maintained in the **ValidationRules.txt** file. The rules below are the currently active validation checks:

**Rule #2: RecordStatus Validation**
- All stored procedures must include a check for `RecordStatus=0` when querying tables
- This ensures that only active records are included in results
- Violation message: "Rule #2: Missing RecordStatus=0 check"

**Rule #3: Naming Convention**
- Procedure names must follow the pattern: `[SCHEMA.]<ProcType>_`
- The `<ProcType>` can be any valid identifier (letters, numbers, special characters)
- The underscore after `<ProcType>` is mandatory
- If schema is specified in the CREATE statement, it must match the file's schema
- Examples of valid names:
  - `RptSrc_OpenPendingActions` (ProcType = RptSrc)
  - `List_DefaultContactRegType` (ProcType = List)
  - `RptSrc_REG_AL_ASC_PendingActionHistoryByFile#` (ProcType = RptSrc, includes special char #)
- Violation messages:
  - "Rule #3: Proc name 'X' doesn't follow naming convention <ProcType>_ (must have underscore)"
  - "Rule #3: Schema mismatch - CREATE statement uses 'X' but filename schema is 'Y'"

### Usage Example

**Mode 1: Export and Validate**
```powershell
PS C:\> C:\StoredProcs\ProcessAndValidate.ps1

Choose operation mode:
  1 = Export and Validate (export procs, then validate)
  2 = Validate Only (validate existing .sql files)
Enter mode (1 or 2): 1
Enter SQL Server instance name: vm-alascsql-sbx.aadds.dorgersoft.com
Enter database name: ASC_Stage_Valence
Enter schema name: ALSC
Enter stored procedure name pattern (e.g., RptSrc_*): RptSrc_*
Enter output folder path (where .sql files are/will be located): C:\ExportedProcs

=== EXPORTING STORED PROCEDURES ===
Found database: ASC_Stage_Valence
Connected to database: ASC_Stage_Valence
Getting stored procedures via SQL query...
Found 12 procedures
Exported: ALSC.RptSrc_OpenPendingActions
Exported: ALSC.RptSrc_CountOfNewFilings
...
Exported 12 stored procedure(s) to C:\ExportedProcs

=== VALIDATING PROCEDURES ===
Validation complete. Results written to: C:\ExportedProcs\Validation_Results.txt

=== PROCESS COMPLETE ===
Exported: 12 procedures
Validation Report: C:\ExportedProcs\Validation_Results.txt
```

**Mode 2: Validate Only**
```powershell
PS C:\> C:\StoredProcs\ProcessAndValidate.ps1

Choose operation mode:
  1 = Export and Validate (export procs, then validate)
  2 = Validate Only (validate existing .sql files)
Enter mode (1 or 2): 2
Enter output folder path (where .sql files are/will be located): C:\ExportedProcs

Skipping export (validate-only mode)

=== VALIDATING PROCEDURES ===
Validation complete. Results written to: C:\ExportedProcs\Validation_Results.txt

=== PROCESS COMPLETE ===
Validation Report: C:\ExportedProcs\Validation_Results.txt
```

---

## Key Technical Features

### Security
- Windows authentication (no password prompts)
- Certificate trust for encrypted connections
- TrustServerCertificate enabled for secure communication

### Reliability
- Comprehensive error handling with try-catch blocks
- Database existence validation before processing
- Individual procedure error handling (continues on failure, logs warning)
- SQL Server connection with LoginSecure and EncryptConnection

### Code Quality
- Regex-based SQL normalization for consistent output
- UTF8 encoding without BOM for version control compatibility
- Modular Normalize-ProcScript function
- Clear section separators and status messaging with color coding

### Flexibility
- Works from any directory
- Exports to any user-specified path
- Supports any schema and naming pattern
- Prompts for all configuration instead of hardcoding

---

## Development Methodology

This solution was built using iterative AI-assisted prompting:
1. **Foundation** - Create core export functionality
2. **Validation** - Add database existence checks
3. **Parameterization** - Replace hardcoded values with dynamic filtering
4. **User Input** - Add prompts for all configuration values
5. **Portability** - Enable execution from any location
6. **Integration** - Combine separate scripts into unified workflow

Each iteration built upon the previous solution, allowing for rapid prototyping and refinement without starting from scratch. This approach reduced development time while maintaining code quality and functionality.
