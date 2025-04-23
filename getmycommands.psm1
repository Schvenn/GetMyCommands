function getmycommands {# Get a list of functions with aliases and details.
$profileDir = Split-Path -Parent $profile; $aliases = @{}; $results = @()

# Read files for aliases.
Get-ChildItem -Path $profileDir -Recurse -Include *.ps1, *.psm1 -File | ForEach-Object {$relativePath = $_.FullName.Substring($profileDir.Length).TrimStart('\','/'); Select-String -Path $_.FullName -Pattern 'sal\s+-name\s+(\S+)\s+-value\s+(\S+)' | ForEach-Object {foreach ($match in $_.Matches) {$alias = $match.Groups[1].Value; $target = $match.Groups[2].Value; $aliases[$target] = $alias}}}

# Read files for functions.
Get-ChildItem -Path $profileDir -Recurse -Include *.ps1, *.psm1 -File | ForEach-Object {$relativePath = $_.FullName.Substring($profileDir.Length).TrimStart('\','/'); Get-Content $_.FullName | ForEach-Object {if ($_ -match '^\s*function\s+([a-zA-Z0-9_-]+)\s*(\(([^\)]*)\))?\s*\{(?:\s*#\s*(.+))?') {$fname = $matches[1]; $priority = switch ($fname) {"background" {0}; "font" {0}; "loadmodules" {0}; "getcolours" {2}; "prompt" {2}; "goback" {4}; "createdosgame" {6}; "dosbox" {6}; "encryptscript" {8}; "execute-encryptedscript" {8}; "updatebash" {10}; "versions" {10}; "movetemp" {12}; "restoretemp" {12}; "ip" {14}; "repairconnection" {14}; "repairwindows" {14}; "shortdir" {14}; "backuppowershell" {16}; "backupthisdir" {16}; "createrestorepoint" {16}; "restorebackup" {16}; "reloadmodule" {18}; "reloadwithoutclear" {18}; "restartandclear" {18}; "showhistory" {18}; "togglelogging" {18}; "details" {20}; "getmycommands" {20}; "viewgotocache" {20}; "bookmark" {22}; "goto" {22}; "locations" {22}; "recent" {22}; "findin" {24}; "getline" {24}; "schvenn" {26}; "edit" {28}; "editmodule" {18}; "editprofile" {28}; "editsandbox" {28}}

# Merge the information into a table.
$results += [PSCustomObject]@{File = $relativePath; Function = $fname; Alias = $aliases[$fname]; Parameters = $matches[3]; Details = $matches[4]; Priority = $priority}}}}

# Sort the output and build the table.
$results = $results | Where-Object {$_.Priority -ge 1} | Sort-Object Priority, Function; Write-Host ""; Write-Host ("File".PadRight(38) + "Function".PadRight(25) + "Alias".PadRight(10) + "Parameters".PadRight(20) + "Details") -ForegroundColor White; Write-Host ("-" * 150) -ForegroundColor Cyan

foreach ($item in $results) {$file = if ($item.File) {$item.File} else {""}; $function = if ($item.Function) {$item.Function} else {""}; $alias = if ($item.Alias) {$item.Alias} else {""}
$parameters = if ($item.Parameters) {if (($item.Parameters.Split(',').Count) -gt 2) {"$($item.Parameters.Split(',').Count) parameters"} else {$item.Parameters}} else {""}; $details = if ($item.Details) {$item.Details} else {""}

# Output to screen with cyan font for the replaced parameters field
Write-Host ($file.PadRight(38)) -NoNewline;  Write-Host ($function.PadRight(25)) -NoNewline -ForegroundColor Yellow; Write-Host ($alias.PadRight(10)) -NoNewline -ForegroundColor Green; if ($parameters -match '\d+ parameters') {Write-Host ($parameters.PadRight(20)) -NoNewline -ForegroundColor Cyan}
else {Write-Host ($parameters.PadRight(20)) -NoNewline -ForegroundColor DarkCyan}
if ($details -like "(Internal)*") {Write-Host $details -ForegroundColor DarkGray} 
else {Write-Host $details -ForegroundColor White}}
Write-Host ""}

function getmoduledetails {# Module file details with function/alias counts
""; font yellow; Write-Host ("Folder".PadRight(15) + "File Name".PadRight(30) + "Functions".PadLeft(10) + "Aliases".PadLeft(10) + "File Size".PadLeft(10) + "Last Modified".PadLeft(20)); Write-Host ("-"*96); $tf=0; $ta=0

Get-ChildItem -Path "$env:UserProfile\Documents\PowerShell\Modules" -Recurse -File | ForEach-Object {$ext = $_.Extension; $name = $_.Name; $folder = $_.Directory.Name.PadRight(15); $fileName = $name.PadRight(30); $fileSize = ('{0:N0}' -f $_.Length).PadLeft(10); $lastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm").PadLeft(20); $fcount = 0; $acount = 0;

if ($ext -match '\.psm1$|\.ps1$') {$lines = Get-Content $_.FullName -Raw -EA SilentlyContinue; $fcount = ($lines -split "`n" | Where-Object {$_ -match '(?i)^function'}).Count; $acount = ($lines -split "`n" | Where-Object {$_ -match '(?i)sal\s+-name'}).Count; $tf += $fcount; $ta += $acount}; $fout = if ($fcount -gt 0) {"$fcount".PadLeft(10)} else {"".PadLeft(10)}; $aout = if ($acount -gt 0) {"$acount".PadLeft(10)} else {"".PadLeft(10)}; $color = switch ($ext) {'.psm1' {'White'}; '.ps1' {'Gray'}; '.psd1' {'White'}; default {'DarkGray'}}; font $color; Write-Host "$folder$fileName$fout$aout$fileSize$lastModified"}; font yellow; Write-Host ("-"*96); Write-Host ("Totals".PadRight(45) + "$tf".PadLeft(10) + "$ta".PadLeft(10)); font white; ""}
sal gmd getmoduledetails
