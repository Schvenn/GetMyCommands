# Get a list of functions with aliases and details.
$profileDir = Split-Path -Parent $profile; $aliases = @{}; $results = @()

# Get a list of aliases.
Get-Alias | ForEach-Object {$aliases[$_.Name] = $_.Definition}

# Read files for functions.
Get-ChildItem -Path $profileDir -Recurse -Include *.ps1, *.psm1 -File | ForEach-Object {$relativePath = $_.FullName.Substring($profileDir.Length).TrimStart('\','/')
if ($_.$FullName -like '*\Powershell\Modules\TestingGround\*') {return}
$content = Get-Content $_.FullName -Raw
if (-not $content) {return}

# Find exported functions list in each file, if it exists.
$exportedFuncs = @(); if ($content -match 'Export-ModuleMember\s+-Function\s+([^\n\r]+)') {$exportLine = $matches[1] -replace '[\(\)\{\}]','' -replace '["'']',''; $exportedFuncs = $exportLine -split '[,\s]+' | Where-Object {$_}}

# Parse remaining information from the file.
$ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null); $ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) | ForEach-Object {$func = $_; $fname = $func.Name; $paramBlock = $func.Body.Find({$args[0] -is [System.Management.Automation.Language.ParamBlockAst]}, $false); $paramList = $func.Parameters | ForEach-Object {$_.Name.VariablePath.UserPath}
if (-not $paramList -or $paramList.Count -eq 0) {$paramBlock = $func.Body.Find({$args[0] -is [System.Management.Automation.Language.ParamBlockAst]}, $false)
if ($paramBlock) {$paramList = $paramBlock.Parameters | ForEach-Object {$_.Name.VariablePath.UserPath}}}
$paramString = if ($paramList.Count -gt 2) {"$($paramList.Count) parameters"}
elseif ($paramList.Count -gt 0) {$paramList -join ', '} else {""}

# Try to find a comment from the first line or inline comment in body
$commentMatch = ($func.Extent.Text -split "`n")[0] -match '#\s*(.+)$'; $detailComment = if ($commentMatch) {$matches[1]} else {""}

# Exclude functions not defined in exported function list.
if ($exportedFuncs -and ($exportedFuncs -notcontains $fname)) {return}

# Match the aliases to the functions.
$aliasList = $aliases.Keys | Where-Object { $aliases[$_] -eq $fname }
$alias = if ($aliasList.Count -gt 1) {"$($aliasList.Count) aliases"} elseif ($aliasList.Count -gt 0) {$aliasList} else {""}
$results += [PSCustomObject]@{File = $relativePath; Function = $fname; Alias = $alias; Parameters = $paramString; Details = $detailComment}}}

# Sort and output
$results = $results | Where-Object {-not [string]::IsNullOrWhiteSpace($_.Details) -and $_.Details -notmatch "(Internal)"} | Sort-Object File, Function; Write-Host ""; Write-Host ("File".PadRight(38) + "Function".PadRight(28) + "Alias".PadRight(12) + "Parameters".PadRight(20) + "Details") -ForegroundColor White; Write-Host ("-" * 150) -ForegroundColor Cyan

foreach ($item in $results) {$file = if ($item.File) {$item.File} else {""}
$function = if ($item.Function) {$item.Function} else {""}; $alias = if ($item.Alias) {$item.Alias} else {""}; $parameters = if ($item.Parameters) {if (($item.Parameters -split ',').Count -gt 2 -and $item.Parameters -notmatch '\d+ parameters') {"$(($item.Parameters -split ',').Count) parameters"} else {$item.Parameters}} else {""}; $details = if ($item.Details) {$item.Details} else {""}

Write-Host ($file.PadRight(38)) -NoNewline; Write-Host ($function.PadRight(28)) -NoNewline -ForegroundColor Yellow
if ($alias -match '^\d+ aliases$') {Write-Host ($alias.PadRight(12)) -NoNewline -ForegroundColor DarkGreen} else {Write-Host ($alias.PadRight(12)) -NoNewline -ForegroundColor Green}
if ($parameters -match '\d+ parameters') {Write-Host ($parameters.PadRight(20)) -NoNewline -ForegroundColor Cyan} else {Write-Host ($parameters.PadRight(20)) -NoNewline -ForegroundColor DarkCyan}
if ($details -like "(Internal)*") {Write-Host $details -ForegroundColor DarkGray} else {Write-Host $details -ForegroundColor White}}

# Totals
$totalFunctions = $results.Count; $totalAliases = ($results | ForEach-Object {if ($_.Alias -match '^(\d+) aliases$') {[int]$matches[1]} elseif ($_.Alias) {($_.Alias -split ', ').Count} else {0}}) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
Write-Host ("-" * 150) -f Cyan; Write-Host -f White $("Totals".PadRight(38) + "$totalFunctions".PadRight(28) + "$totalAliases".PadRight(12)); Write-Host ("-" * 150) -f Cyan; ""
