#Requires -Version 5.1
[CmdletBinding()]
param([string]$AutorunsCsv,[string]$Baseline)
$ErrorActionPreference = 'Stop'
$entries = @()
$warnings = @()
if ($AutorunsCsv) {
    $mode = 'Autorunsc CSV'
    $rows = @(Import-Csv -LiteralPath $AutorunsCsv)
    if (!$rows.Count -or 'Entry Location' -notin $rows[0].PSObject.Properties.Name -or 'Entry' -notin $rows[0].PSObject.Properties.Name) { throw 'Expected Autorunsc CSV headers Entry Location and Entry, and at least one row.' }
    $entries = @(foreach ($row in $rows) {
        [pscustomobject]@{Location=$row.'Entry Location'; Name=$row.Entry; User=$row.Profile; Target=$row.'Image Path'; Command=$row.'Launch String'; Enabled=$row.Enabled}
    })
} else {
    $mode = 'Native Run and RunOnce'
    $entries = @(foreach ($scope in 'HKLM','HKCU') {
        foreach ($branch in 'SOFTWARE','SOFTWARE\Wow6432Node') {
            foreach ($kind in 'Run','RunOnce') {
                $path = $scope + ':\' + $branch + '\Microsoft\Windows\CurrentVersion\' + $kind
                try {
                    if (Test-Path -LiteralPath $path) {
                        $key = Get-Item -LiteralPath $path
                        foreach ($name in $key.GetValueNames()) {
                            [pscustomobject]@{Location=$path; Name=$name; User=$scope; Target=$null; Command=$key.GetValue($name); Enabled=$null}
                        }
                    }
                } catch { $warnings += "Incomplete location $path" }
            }
        }
    })
}
function Get-Identity($entry) { ConvertTo-Json -Compress -InputObject @($entry.Location,$entry.User,$entry.Name) }
$changes = @()
$baselineWarnings = @()
if ($Baseline) {
    $old = Get-Content -Raw -LiteralPath $Baseline | ConvertFrom-Json
    if ($old.Format -ne 'startup-1' -or $old.Mode -ne $mode -or $old.Entries -isnot [array]) { throw 'Use a baseline from the same collection mode.' }
    $previous = @{}
    $current = @{}
    foreach ($entry in $old.Entries) {
        $previous.Add((Get-Identity $entry),$entry)
    }
    $changes = @(foreach ($entry in $entries) {
        $id = Get-Identity $entry
        $current.Add($id,$entry)
        $before = $previous[$id]
        $state = if (!$before) { 'Newly observed' }
            elseif ($entry.Command -cne $before.Command -or $entry.Enabled -ne $before.Enabled -or $entry.Target -cne $before.Target) { 'Changed' }
        if ($state) { [pscustomobject]@{State=$state; Before=$before; After=$entry} }
    }
    foreach ($id in $previous.Keys) {
        if (!$current.ContainsKey($id)) { [pscustomobject]@{State='No longer observed'; Before=$previous[$id]; After=$null} }
    })
    $baselineWarnings = @($old.Warnings | Where-Object { $_ })
}
[pscustomobject]@{Format='startup-1'; Mode=$mode; CapturedUtc=[datetime]::UtcNow.ToString('o'); Entries=$entries; Changes=$changes; Warnings=$warnings; BaselineWarnings=$baselineWarnings} | ConvertTo-Json -Depth 6
