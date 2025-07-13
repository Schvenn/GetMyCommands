$script:powershell = Split-Path $profile

function getmycommands ($mode, [switch]$help) {# Get a list of functions with aliases and details.
$profileDir = Split-Path -Parent $profile; $aliases = @{}; $results = @()

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function help {# Inline help.
function scripthelp ($section) {# (Internal) Generate the help sections from the comments section of the script.
line yellow 100 -pre; $pattern = "(?ims)^## ($section.*?)(##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; Write-Host $lines[0] -f yellow; line yellow 100
if ($lines.Count -gt 1) {wordwrap $lines[1] 100 | Write-Host -f white | Out-Host -Paging}; line yellow 100}
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)")
if ($sections.Count -eq 1) {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help:" -f cyan; scripthelp $sections[0].Groups[1].Value; ""; return}

$selection = $null
do {cls; Write-Host "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n" -f cyan; for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host "$($i + 1). " -f cyan -n; Write-Host $sections[$i].Groups[1].Value -f white}
if ($selection) {scripthelp $sections[$selection - 1].Groups[1].Value}
Write-Host -f yellow "`nEnter a section number to view " -n; $input = Read-Host
if ($input -match '^\d+$') {$index = [int]$input
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index}
else {$selection = $null}} else {""; return}}
while ($true); return}

# External call to help.
if ($help) {help; return}

function loadconfiguration {$script:baseModulePath = "$powershell\Modules\GetMyCommands"; $script:configPath = Join-Path $baseModulePath "GetMyCommands.psd1"
if (!(Test-Path $configPath)) {throw "Config file not found at $configPath"}
$script:config = Import-PowerShellDataFile -Path $configPath

# Pull config values into variables
$script:fpad = $config.privatedata.fpad
$script:fnpad = $config.privatedata.fnpad
$script:apad = $config.privatedata.apad
$script:ppad = $config.privatedata.ppad}
loadconfiguration

function line ($colour, $length, [switch]$pre, [switch]$post) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
Write-Host -f $colour ("-" * $length)
if ($post) {Write-Host ""}}

if ($mode -match "(?i)^details$") {# Module file details with function/alias counts.
""; Write-Host -f white ("Folder".PadRight(20) + "File Name".PadRight(30) + "Functions".PadLeft(10) + "Aliases".PadLeft(10) + "File Size".PadLeft(10) + "Last Modified".PadLeft(20)); line cyan 130; $tf=0; $ta=0; Get-ChildItem -Path "$powerShell\Modules" -Recurse -File | ForEach-Object {$ext = $_.Extension; $name = $_.Name; $folder = $_.Directory.Name.PadRight(20); $fileName = $name.PadRight(30); $fileSize = ('{0:N0}' -f $_.Length).PadLeft(10); $lastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm").PadLeft(20); $fcount = 0; $acount = 0
if ($ext -match '\.psm1$|\.ps1$') {$lines = Get-Content $_.FullName -Raw -EA SilentlyContinue; $fcount = ($lines -split "`n" | Where-Object {$_ -match '(?i)^function'}).Count; $acount = ($lines -split "`n" | Where-Object {$_ -match '(?i)sal\s+-name'}).Count; $tf += $fcount; $ta += $acount}; $fout = if ($fcount -gt 0) {"$fcount".PadLeft(10)} else {"".PadLeft(10)}; $aout = if ($acount -gt 0) {"$acount".PadLeft(10)} else {"".PadLeft(10)}; $color = switch ($ext) {'.psm1' {'White'}; '.ps1' {'Gray'}; '.psd1' {'White'}; default {'DarkGray'}}; [console]::foregroundcolor = "$color"; Write-Host "$folder$fileName$fout$aout$fileSize$lastModified"}; line cyan 130; Write-Host -f white ("Totals".PadRight(50) + "$tf".PadLeft(10) + "$ta".PadLeft(10)); line cyan 130 -post; return}

if ($mode -match "(?i)^aliases$") {# Get a list of aliases mapped to my functions.
$profileDir = Split-Path -Parent $profile; $aliases = @{}; $results = @()  # Initialize the results array
Get-Alias | ForEach-Object {$aliases[$_.Name] = $_.Definition}
Get-ChildItem -Path $profileDir -Recurse -Include *.ps1, *.psm1 -File | ForEach-Object {$content = Get-Content $_.FullName -Raw
if (-not $content) {return}
$ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null); $ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) | ForEach-Object {$funcName = $_.Name
$aliasList = $aliases.Keys | Where-Object {$aliases[$_] -eq $funcName}
if ($aliasList.Count -gt 0) {$aliasNames = $aliasList -join ", "; $results += [PSCustomObject]@{Function = $funcName; Aliases = $aliasNames}}}}
if ($results.Count -gt 0) {Write-Host -f white "`nFunction".PadRight(30)"Alias"; line cyan 130; $totalAliases = 0; $results | Sort-Object Function | ForEach-Object {Write-Host -f yellow ($_.Function.PadRight(30)) -n; Write-Host -f green ($_.Aliases); $totalAliases += ($_.Aliases -split ',').Count}
line cyan 130; Write-Host -f white ("Total Aliases:".PadRight(30) + "$totalAliases"); line cyan 130; Write-Host -f darkgreen "Note: This list also contains functions that are (Internal) or contain no comment line."}; ""; return}

if ($mode -match "(?i)^quick$") {# Get an abbreviated list of all custom modules.
$modulelist=Get-ChildItem "$powerShell\Modules" -Directory; $modules=$modulelist.Name; $pad=($modules|Measure-Object -Maximum Length).Maximum+2; ""; Write-Host -f white ("Module:".PadRight($pad)+"Functions:"); line cyan 130; foreach ($module in $modules) {$cmds = (Get-Command -ErrorAction SilentlyContinue | Where-Object { $_.Source -eq $module }).Name; if ($cmds) {Write-Host -f cyan ($module+":").PadRight($pad) -n; Write-Host -f yellow ($cmds -join ", ")}}; line cyan 130 -post; return}

# Get a list of aliases.
Get-Alias | ForEach-Object {$aliases[$_.Name] = $_.Definition}

# Read files for functions.
Get-ChildItem -Path $profileDir -Recurse -Include *.ps1, *.psm1 -File | ForEach-Object {$relativePath = $_.FullName.Substring($profileDir.Length).TrimStart('\','/')
if ($_.$FullName -like '*\Modules\TestingGround\*') {return}
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
$results = $results | Where-Object {-not [string]::IsNullOrWhiteSpace($_.Details) -and $_.Details -notmatch "(Internal)"} | Sort-Object File, Function; Write-Host ""; Write-Host ("File".PadRight($fpad) + "Function".PadRight($fnpad) + "Alias".PadRight($apad) + "Parameters".PadRight($ppad) + "Details") -f white; line cyan

foreach ($item in $results) {$file = if ($item.File) {$item.File} else {""}
$function = if ($item.Function) {$item.Function} else {""}; $alias = if ($item.Alias) {$item.Alias} else {""}; $parameters = if ($item.Parameters) {if (($item.Parameters -split ',').Count -gt 2 -and $item.Parameters -notmatch '\d+ parameters') {"$(($item.Parameters -split ',').Count) parameters"} else {$item.Parameters}} else {""}; $details = if ($item.Details) {$item.Details} else {""}

Write-Host ($file.PadRight($fpad)) -n; Write-Host -f yellow ($function.PadRight($fnpad)) -n
if ($alias -match '^\d+ aliases$') {Write-Host -f darkgreen ($alias.PadRight($apad)) -n} else {Write-Host -f green ($alias.PadRight($apad)) -n}
if ($parameters -match '\d+ parameters') {Write-Host -f cyan ($parameters.PadRight($ppad)) -n} else {Write-Host -f darkcyan ($parameters.PadRight($ppad)) -n}
if ($details -like "(Internal)*") {Write-Host $details -f darkgray} else {Write-Host $details -f white}}

# Totals
$totalFunctions = $results.Count; $totalAliases = ($results | ForEach-Object {if ($_.Alias -match '^(\d+) aliases$') {[int]$matches[1]} elseif ($_.Alias) {($_.Alias -split ', ').Count} else {0}}) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
line cyan; Write-Host -f white $("Totals".PadRight($fpad) + "$totalFunctions".PadRight($fnpad) + "$totalAliases"); line cyan -post}
sal -name gmc -value getmycommands

Export-ModuleMember -Function getmycommands
Export-ModuleMember -Alias gmc

<#
## GetMyCommands
This module provides detailed tables of all functions and aliases loaded under the current user profile:

		Usage: getmycommands <details/assets/quick> <-help>

• The default table provides a table of files, functions, aliases, parameters and a brief explanation of the function, taken from the first comment line.
	
• Details mode provides an alternate table that presents all folders, files and resources, as well as their last modified date and totals.

• Assets mode provides a list of all aliases, including those which may not hidden from the main table.

• Quick mode provides a comma separated list of functions as they relate to their parent module.
## License
MIT License

Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>
