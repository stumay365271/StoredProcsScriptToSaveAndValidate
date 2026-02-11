# SQL Server Stored Procedure Export & Validation Tool

## Overview
An AI-assisted PowerShell solution for exporting and validating SQL Server stored procedures during database migrations and conversions.

## Recreating This Project

This project was built entirely through AI-assisted development. The complete development process is documented in **PROMPT_DOCUMENTATION.md**.

### To Recreate From Scratch

If you have only the PROMPT_DOCUMENTATION.md file:

1. Open the documentation file and review the 7 prompts listed
2. Provide each prompt (in sequence) to an AI assistant
3. The AI will generate the complete ProcessAndValidate.ps1 script

**The prompt documentation serves as a complete blueprint for recreation.** Each prompt describes what to ask for and what the expected result should be, allowing anyone to rebuild the entire solution from an empty folder.

## What This Solution Does

- **Exports** stored procedures from SQL Server to individual .sql files in a folder you specify
- **Validates** procedures against business rules (naming conventions, RecordStatus checks)
- **Reports** compliance violations in a detailed validation report
- **Dual-mode operation**: Export+Validate or Validate-Only
- **Extensible validation**: Add new rules via ValidationRules.txt with step-by-step instructions

## Files Included

- **ProcessAndValidate.ps1** - The main PowerShell script
- **ValidationRules.txt** - Business rules configuration with instructions for adding new rules
- **PROMPT_DOCUMENTATION.md** - Complete prompt history showing how this was built
- **README.md** - The Project Cover Sheet
- **USAGE ReadMe.md** This file

## Usage

Run the script and follow the interactive prompts:

```powershell
.\ProcessAndValidate.ps1
```

Choose your operation mode:
- **Mode 1**: Export and Validate (connects to SQL Server, exports procedures, validates them)
- **Mode 2**: Validate Only (validates existing .sql files without re-exporting)

## Key Features

- Windows authentication with encrypted connections
- Dynamic filtering by schema and naming patterns
- Consistent SQL formatting (removes SET statements, normalizes CREATE statements)
- UTF8 encoding for version control compatibility
- Comprehensive error handling
- Color-coded progress feedback
- Detailed validation reporting
- Configurable validation rules with documentation

## Requirements

- PowerShell 5.1 or higher
- SQL Server Management Objects (SMO)
- Windows authentication access to target SQL Server
- Write permissions to output folder

## Development Approach

This project demonstrates the power of AI-assisted development through iterative prompting. Rather than writing code manually, the solution was built by:

1. Defining clear requirements in natural language
2. Submitting focused prompts to an AI assistant
3. Iteratively refining and expanding functionality
4. Building a production-ready tool in a single session

The PROMPT_DOCUMENTATION.md file captures this entire process, making it fully reproducible.

