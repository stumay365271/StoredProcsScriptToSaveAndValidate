$ErrorActionPreference = 'Stop'

# Prompt for mode
Write-Host "\nChoose operation mode:"
Write-Host "  1 = Export and Validate (export procs, then validate)"
Write-Host "  2 = Validate Only (validate existing .sql files)"
$mode = Read-Host "Enter mode (1 or 2)"

if ($mode -notin @('1', '2')) {
    Write-Error "Invalid mode. Please enter 1 or 2."
    exit
}

# Prompt for configuration values
if ($mode -eq '1') {
    $ServerInstance = Read-Host "Enter SQL Server instance name"
    $DatabaseTarget = Read-Host "Enter database name"
    $SchemaName     = Read-Host "Enter schema name"
    $NamePattern    = Read-Host "Enter stored procedure name pattern (e.g., RptSrc_*)"
}

$OutputPath     = Read-Host "Enter output folder path (where .sql files are/will be located)"

if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Import-Module SqlServer -ErrorAction Stop

# ============================================================================
# SECTION 1: EXPORT STORED PROCEDURES (Mode 1 only)
# ============================================================================

if ($mode -eq '1') {
    Write-Host "`n=== EXPORTING STORED PROCEDURES ===" -ForegroundColor Cyan

# Query databases via SQL instead of SMO enumeration
try {
    $databases = Invoke-Sqlcmd -ServerInstance $ServerInstance `
                                -Database "master" `
                                -Query "SELECT name FROM sys.databases WHERE state = 0" `
                                -TrustServerCertificate `
                                -ErrorAction Stop
    
    $dbMatch = $databases | Where-Object { $_.name -ieq $DatabaseTarget }
    
    if (-not $dbMatch) {
        Write-Host "Available databases:"
        $databases | ForEach-Object { Write-Host "  $($_.name)" }
        throw "Database '$DatabaseTarget' not found"
    }
    
    $actualDbName = $dbMatch.name
    Write-Host "Found database: $actualDbName" -ForegroundColor Green
}
catch {
    Write-Error "Failed to query databases: $($_.Exception.Message)"
    exit
}

# Now connect to the specific database
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server($ServerInstance)
$srv.ConnectionContext.LoginSecure = $true
$srv.ConnectionContext.TrustServerCertificate = $true
$srv.ConnectionContext.EncryptConnection = $true

$db = $srv.Databases[$actualDbName]
if (-not $db) {
    throw "Could not access database '$actualDbName'"
}

Write-Host "Connected to database: $($db.Name)"

# Scripter setup
$scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter($srv)
$scripter.Options.SchemaQualify = $true
$scripter.Options.NoCollation = $true
$scripter.Options.NoFileGroup = $true
$scripter.Options.IncludeDatabaseContext = $false
$scripter.Options.IncludeIfNotExists = $false
$scripter.Options.EnforceScriptingOptions = $true

function Normalize-ProcScript([string]$text) {
    $t = $text -replace "(?im)^\s*SET\s+ANSI_NULLS\s+\w+\s*;?\s*$", ""
    $t = $t -replace "(?im)^\s*SET\s+QUOTED_IDENTIFIER\s+\w+\s*;?\s*$", ""
    $t = $t -replace "(?im)^\s*GO\s*$", ""
    # Convert CREATE/ALTER PROC to CREATE OR ALTER PROC
    $t = $t -replace "(?im)^\s*(?:CREATE|ALTER)\s+(?:OR\s+ALTER\s+)?(PROC|PROCEDURE)\s+", "CREATE OR ALTER PROC "
    return ($t.Trim() + [Environment]::NewLine)
}

Write-Host "Getting stored procedures via SQL query..."

$procQuery = @"
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcName
FROM sys.procedures
WHERE name LIKE '$($NamePattern.Replace('*','%'))'
AND SCHEMA_NAME(schema_id) LIKE '$($SchemaName.Replace('*','%'))'
ORDER BY name
"@

$procList = Invoke-Sqlcmd -ServerInstance $ServerInstance `
                          -Database $actualDbName `
                          -Query $procQuery `
                          -TrustServerCertificate `
                          -ErrorAction Stop

Write-Host "Found $($procList.Count) procedures"

if ($procList.Count -eq 0) {
    Write-Warning "No procedures found matching '$NamePattern'"
    exit
}

# Clear existing .sql files before export
    Write-Host "Clearing existing .sql files from $OutputPath..."
    Get-ChildItem "$OutputPath\*.sql" -ErrorAction SilentlyContinue | Remove-Item -Force

$exported = 0
foreach ($procRow in $procList) {
    try {
        $proc = $db.StoredProcedures[$procRow.ProcName, $procRow.SchemaName]
        
        $fileName = Join-Path $OutputPath ("{0}.{1}.sql" -f $procRow.SchemaName, $procRow.ProcName)
        $rawScript = $scripter.Script($proc) -join [Environment]::NewLine
        $cleanScript = Normalize-ProcScript $rawScript
        
        [System.IO.File]::WriteAllText($fileName, $cleanScript, (New-Object System.Text.UTF8Encoding($false)))
        
        Write-Host "Exported: $($procRow.SchemaName).$($procRow.ProcName)"
        $exported++
    }
    catch {
        Write-Warning "Failed: $($procRow.SchemaName).$($procRow.ProcName) - $($_.Exception.Message)"
    }
}

    Write-Host "`nExported $exported stored procedure(s) to $OutputPath" -ForegroundColor Green
} else {
    Write-Host "`nSkipping export (validate-only mode)" -ForegroundColor Yellow
}

# ============================================================================
# SECTION 2: VALIDATE EXPORTED PROCEDURES
# ============================================================================

Write-Host "`n=== VALIDATING PROCEDURES ===" -ForegroundColor Cyan

$validationOutputFile = Join-Path $OutputPath "Validation_Results.txt"
$validationResults = @()

Get-ChildItem "$OutputPath\*.sql" | ForEach-Object {
    $fileName = $_.Name
    $violations = @()
    
    $content = Get-Content $_.FullName -Raw

    # Rule 2: Should check RecordStatus=0 on at least one table
    $hasRecordStatusCheck = $content -match 'RecordStatus\s*=\s*0'
    if (-not $hasRecordStatusCheck) {
        $violations += "Rule #2: Missing RecordStatus=0 check"
    }
    
    # Rule 3: Proc name should follow format [SCHEMA.]<ProcType>_ where SCHEMA must match if present
    # Match: CREATE OR ALTER PROC [SCHEMA].[PROCNAME] or CREATE OR ALTER PROC [PROCNAME]
    $procNameMatch = $content -match '(?:CREATE|ALTER)\s+(?:OR\s+ALTER\s+)?(?:PROC|PROCEDURE)\s+(?:\[([^\]]+)\]\.\[([^\]]+)\]|\[([^\]]+)\])'
    
    if ($procNameMatch) {
        $schema = $null
        $procName = $null
        
        if ($matches[1] -and $matches[2]) {
            # Format: [SCHEMA].[PROCNAME]
            $schema = $matches[1]
            $procName = $matches[2]
        } elseif ($matches[3]) {
            # Format: [PROCNAME] only
            $procName = $matches[3]
        }
        
        # Check if proc name follows <ProcType>_ pattern (has underscore)
        if ($procName -and $procName -notmatch '^\w+_') {
            $violations += "Rule #3: Proc name '$procName' doesn't follow naming convention <ProcType>_ (must have underscore)"
        }
        
        # Check if schema in CREATE statement matches the schema from the file (SCHEMA.PROCNAME.sql)
        if ($schema) {
            # Extract schema from filename: SCHEMA.PROCNAME.sql (format uses dot separator)
            $fileSchemaMatch = $fileName -match '^([^\.]+)\.'
            if ($fileSchemaMatch) {
                $fileSchema = $matches[1]
                if ($schema -ine $fileSchema) {
                    $violations += "Rule #3: Schema mismatch - CREATE statement uses '$schema' but filename schema is '$fileSchema'"
                }
            }
        }
    } else {
        $violations += "Rule #3: Could not parse proc name from CREATE statement"
    }
    
    if ($violations.Count -gt 0) {
        $validationResults += "`n=== $fileName ==="
        $violations | ForEach-Object { $validationResults += "  $_" }
    }
}

if ($validationResults.Count -eq 0) {
    $validationResults += "All stored procedures passed validation!"
}

$validationResults | Out-File $validationOutputFile
Write-Host "Validation complete. Results written to: $validationOutputFile" -ForegroundColor Green

Write-Host "`n=== PROCESS COMPLETE ===" -ForegroundColor Green
Write-Host "Exported: $exported procedures"
Write-Host "Validation Report: $validationOutputFile"
