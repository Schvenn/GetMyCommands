function font {param($newcolour); [console]::foregroundcolor = "$newcolour"}

function getmycommands {# Get a list of functions with aliases and details.
$profileDir = Split-Path -Parent $profile; $aliases = @{}; $results = @()

function loadconfiguration{
$script:baseModulePath = if ($PSVersionTable.PSEdition -eq 'Core') {"$env:USERPROFILE\Documents\Powershell\Modules\GetMyCommands"} else {"$env:USERPROFILE\Documents\WindowsPowerShell\Modules\GetMyCommands"}
$script:configPath = Join-Path $baseModulePath "GetMyCommands.psd1"; if (!(Test-Path $configPath)) {throw "Config file not found at $configPath"}
$script:config = Import-PowerShellDataFile -Path $configPath

# Pull config values into variables
$script:fpad = $config.privatedata.fpad
$script:fnpad = $config.privatedata.fnpad
$script:apad = $config.privatedata.apad
$script:ppad = $config.privatedata.ppad}
loadconfiguration

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
$results = $results | Where-Object {-not [string]::IsNullOrWhiteSpace($_.Details) -and $_.Details -notmatch "(Internal)"} | Sort-Object File, Function; Write-Host ""; Write-Host ("File".PadRight($fpad) + "Function".PadRight($fnpad) + "Alias".PadRight($apad) + "Parameters".PadRight($ppad) + "Details") -ForegroundColor White; Write-Host ("-" * 150) -ForegroundColor Cyan

foreach ($item in $results) {$file = if ($item.File) {$item.File} else {""}
$function = if ($item.Function) {$item.Function} else {""}; $alias = if ($item.Alias) {$item.Alias} else {""}; $parameters = if ($item.Parameters) {if (($item.Parameters -split ',').Count -gt 2 -and $item.Parameters -notmatch '\d+ parameters') {"$(($item.Parameters -split ',').Count) parameters"} else {$item.Parameters}} else {""}; $details = if ($item.Details) {$item.Details} else {""}

Write-Host ($file.PadRight($fpad)) -NoNewline; Write-Host ($function.PadRight($fnpad)) -NoNewline -ForegroundColor Yellow
if ($alias -match '^\d+ aliases$') {Write-Host ($alias.PadRight($apad)) -NoNewline -ForegroundColor DarkGreen} else {Write-Host ($alias.PadRight($apad)) -NoNewline -ForegroundColor Green}
if ($parameters -match '\d+ parameters') {Write-Host ($parameters.PadRight($ppad)) -NoNewline -ForegroundColor Cyan} else {Write-Host ($parameters.PadRight($ppad)) -NoNewline -ForegroundColor DarkCyan}
if ($details -like "(Internal)*") {Write-Host $details -ForegroundColor DarkGray} else {Write-Host $details -ForegroundColor White}}

# Totals
$totalFunctions = $results.Count; $totalAliases = ($results | ForEach-Object {if ($_.Alias -match '^(\d+) aliases$') {[int]$matches[1]} elseif ($_.Alias) {($_.Alias -split ', ').Count} else {0}}) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
Write-Host ("-" * 150) -f Cyan; Write-Host -f White $("Totals".PadRight(42) + "$totalFunctions".PadRight(20) + "$totalAliases"); Write-Host ("-" * 150) -f Cyan; ""}
sal -name gmc -value getmycommands

function getmoduledetails {# Module file details with function/alias counts.
""; font yellow; Write-Host ("Folder".PadRight(15) + "File Name".PadRight(30) + "Functions".PadLeft(10) + "Aliases".PadLeft(10) + "File Size".PadLeft(10) + "Last Modified".PadLeft(20)); Write-Host ("-"*96); $tf=0; $ta=0; Get-ChildItem -Path "$env:UserProfile\Documents\PowerShell\Modules" -Recurse -File | ForEach-Object {$ext = $_.Extension; $name = $_.Name; $folder = $_.Directory.Name.PadRight(15); $fileName = $name.PadRight(30); $fileSize = ('{0:N0}' -f $_.Length).PadLeft(10); $lastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm").PadLeft(20); $fcount = 0; $acount = 0
if ($ext -match '\.psm1$|\.ps1$') {$lines = Get-Content $_.FullName -Raw -EA SilentlyContinue; $fcount = ($lines -split "`n" | Where-Object {$_ -match '(?i)^function'}).Count; $acount = ($lines -split "`n" | Where-Object {$_ -match '(?i)sal\s+-name'}).Count; $tf += $fcount; $ta += $acount}; $fout = if ($fcount -gt 0) {"$fcount".PadLeft(10)} else {"".PadLeft(10)}; $aout = if ($acount -gt 0) {"$acount".PadLeft(10)} else {"".PadLeft(10)}; $color = switch ($ext) {'.psm1' {'White'}; '.ps1' {'Gray'}; '.psd1' {'White'}; default {'DarkGray'}}; font $color; Write-Host "$folder$fileName$fout$aout$fileSize$lastModified"}; font yellow; Write-Host ("-"*96); Write-Host ("Totals".PadRight(45) + "$tf".PadLeft(10) + "$ta".PadLeft(10)); font gray; ""}
sal -name gmd -value getmoduledetails

function getmyaliases {# Get a list of aliases mapped to my functions.
$profileDir = Split-Path -Parent $profile; $aliases = @{}; $results = @()  # Initialize the results array
Get-Alias | ForEach-Object {$aliases[$_.Name] = $_.Definition}
Get-ChildItem -Path $profileDir -Recurse -Include *.ps1, *.psm1 -File | ForEach-Object {$content = Get-Content $_.FullName -Raw
if (-not $content) {return}
$ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null); $ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) | ForEach-Object {$funcName = $_.Name
$aliasList = $aliases.Keys | Where-Object {$aliases[$_] -eq $funcName}
if ($aliasList.Count -gt 0) {$aliasNames = $aliasList -join ", "; $results += [PSCustomObject]@{Function = $funcName; Aliases = $aliasNames}}}}
if ($results.Count -gt 0) {Write-Host -f white "`nFunction".PadRight(30)"Alias"; Write-Host -f cyan ("-" * 100); $totalAliases = 0; $results | Sort-Object Function | ForEach-Object {Write-Host -f yellow ($_.Function.PadRight(30)) -NoNewline; Write-Host -f green ($_.Aliases); $totalAliases += ($_.Aliases -split ',').Count}
Write-Host -f cyan ("-" * 100); Write-Host -f white ("Total Aliases:".PadRight(30) + "$totalAliases"); Write-Host -f darkgreen "Note: This list also contains functions that are (Internal) or contain no comment line."}; ""}
sal -name gma -value getmyaliases

function quicklist {# Get an abbreviated list of all custom modules.
$modulelist=Get-ChildItem "$env:UserProfile\Documents\PowerShell\Modules" -Directory; $modules=$modulelist.Name; $pad=($modules|Measure-Object -Maximum Length).Maximum+2; ""; Write-Host ("Module:".PadRight($pad)+"Functions:") -ForegroundColor Yellow; foreach ($module in $modules) {$cmds=(Get-Command -Module $module -ErrorAction SilentlyContinue).Name; if ($cmds) {Write-Host -ForegroundColor Cyan ($module+":").PadRight($pad) -NoNewLine; Write-Host ($cmds -join ", ")}}; ""}

Export-ModuleMember -Function getmycommands, getmoduledetails, getmyaliases, quicklist
Export-ModuleMember -Alias gmc, gmd, gma
