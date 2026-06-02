# Lab Evidence — Findings Summary

All output below was captured from a live Windows 10 Home VM running in Oracle VirtualBox. Screenshots referenced are in the screenshots folder.

---

## Scenario 1 — System Health Report

Script: `Get-SystemHealthReport.ps1`

| Check | Result | Assessment |
|-------|--------|------------|
| Uptime | ~36 minutes (recently booted) | Normal — not a factor |
| Top CPU | MsMpEng (Defender), splunkd, System, mongod, fleet-server | Normal — Defender boot scan + homelab stack |
| Top RAM | fleet-server (~252 MB), MsMpEng, splunkd, filebeat x2 | Yellow — two Filebeat instances noted |
| Disk C: | 48.54 GB used / 10.34 GB free (~82%) | Yellow — approaching 85–90% threshold |
| Disk D: | 100% (VirtualBox virtual disk) | Normal for VM |
| System errors (24h) | Event 6008 (unexpected shutdown) x2, Event 10010 (DCOM timeout), Event 1801 (TPM/Secure Boot) | Low — all consistent with a VM environment |

Conclusion: System is functional. Perceived slowness is explained by the homelab stack (Splunk + Elastic + MongoDB) consuming memory, not a fault. Recommendation: free space on C: and monitor fleet-server memory.

Screenshots: 01-uptime.png, 02-top-cpu-processes.png, 03-top-ram-processes.png, 04-disk-usage.png, 05-system-events.png, 07-health-report-full.png

---

## Scenario 2 — Service Failure Diagnostic

Simulated ticket: printing failure.

| Step | Result |
|------|--------|
| Baseline | Spooler — Status: Running, StartType: Automatic |
| Fault induced | Stop-Service Spooler -Force, Status: Stopped |
| Auto-detection | 4 stopped automatic services found: edgeupdate, MapsBroker, Spooler, sppsvc |
| Correlation | Symptom (printing) maps to Spooler; others are trigger-start, unrelated |
| Deep inspection | Win32_Service: StartMode Auto, StartName LocalSystem (correct) |
| Remediation | Start-Service Spooler, Status: Running |

Conclusion: Spooler confirmed as root cause via symptom correlation. Restart resolved the issue; other stopped services correctly identified as normal.

Screenshots: 08-spooler-before.png, 09-spooler-stopped.png, 10-spooler-restarted.png

---

## Scenario 4 — Failed Logon Report

Reproduced end to end with real data.

| Step | Result |
|------|--------|
| Users created | jdoe (Sales), msmith (HR), dgonzalez (IT) — all local, Enabled |
| Lockout policy | threshold 3, duration 5 min, window 5 min (resolved System error 87 by setting window before duration) |
| Failed logons generated | 3 attempts against jdoe with wrong password, 11:46:12 to 11:47:31 (75 seconds) |
| Lock confirmed | net user jdoe, Account active: Locked |
| 4625 events | 3 recent (jdoe, today) + 2 old (GoldRoguer, 4/29) |
| Account extraction | Properties[5].Value: jdoe, jdoe, jdoe, GoldRoguer, GoldRoguer |
| Triage | 3 failures in 75s on a never-used account: scripted/brute-force pattern, not user error. April GoldRoguer events = unrelated noise |
| Remediation | net user jdoe /active:yes, Account active: Yes |

Conclusion: Lockout reproduced and resolved. Pattern analysis distinguished the active incident from historical noise via timestamp correlation. This scenario bridges Help Desk and SOC analysis.

Screenshots: 11-users-created.png, 12-lockout-policy.png, 13-account-locked.png, 14-failed-logon-accounts.png, 15-account-unlocked.png
