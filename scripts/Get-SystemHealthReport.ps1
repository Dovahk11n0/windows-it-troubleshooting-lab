# ================================================
# Get-SystemHealthReport.ps1
# Author: Diago Gonzalez | github.com/Dovahk11n0
# Description: First-response diagnostics for Help Desk Tier 1
# Usage: Run as Administrator
# ================================================

Write-Host "=============================" -ForegroundColor Cyan
Write-Host " SYSTEM HEALTH REPORT" -ForegroundColor Cyan
Write-Host " Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

Write-Host "[1] SYSTEM UPTIME" -ForegroundColor Yellow
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "Last Boot Time: $($os.LastBootUpTime)"
Write-Host "System Uptime: $($uptime.Days) days $($uptime.Hours) hours $($uptime.Minutes) minutes"

Write-Host "[2] TOP 5 PROCESSES BY CPU" -ForegroundColor Yellow
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, Id, CPU, WorkingSet64 | Format-Table -AutoSize

Write-Host "[3] TOP 5 PROCESSES BY MEMORY" -ForegroundColor Yellow
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, Id, WorkingSet64 | Format-Table -AutoSize

Write-Host "[4] DISK USAGE" -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Format-Table Name, Root, Used, Free -AutoSize

Write-Host "[5] RECENT SYSTEM ERRORS (Last 24 hours)" -ForegroundColor Yellow
$since = (Get-Date).AddHours(-24)
$errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=$since} -ErrorAction SilentlyContinue
if ($errors) {
    $errors | Select-Object -First 5 TimeCreated, Id, ProviderName | Format-Table -AutoSize
} else {
    Write-Host "No critical errors found in the last 24 hours." -ForegroundColor Green
}

Write-Host "=============================" -ForegroundColor Cyan
Write-Host " END OF REPORT" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
