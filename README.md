# Windows Startup Agent

Compare Windows startup snapshots and explain newly observed, changed or missing sign-in entries. Works from native Run and RunOnce keys or a Sysinternals Autorunsc CSV.

Feel free to test locally by comparing a saved Autorunsc CSV with a baseline made from the same CSV. Expect an empty `Changes` array.

## For AI agents

Start with [AGENTS.md](AGENTS.md). Run the scripts as the signed-in user in Windows PowerShell 5.1. Keep reports local unless the owner chooses to share them.

## Usage

```powershell
.\Review-Startup.ps1 | Set-Content -Encoding UTF8 baseline.json
.\Review-Startup.ps1 -Baseline .\baseline.json
```

Run the first command before the period of interest and the second afterward. For wider coverage, provide -AutorunsCsv with an Autorunsc CSV on both runs. Use the same PC, user, bitness and capture settings. Native mode reads registry registrations; it cannot see all startup mechanisms or confirm enabled state. Autorunsc exports with duplicate location/profile/name identities need disambiguation before comparison.
