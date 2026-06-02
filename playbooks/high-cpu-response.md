# Playbook: Slow System / High Resource Usage

**Ticket type:** System running slow
**Severity:** Low–Medium
**Target response:** 30 minutes

## Step 1 — Validate the symptom
"Slow" is subjective. Run `Get-SystemHealthReport.ps1` to turn the complaint into measurable data: uptime, CPU, memory, disk, and recent errors. Confirm what is actually constrained before acting.

## Step 2 — Check uptime
A system up for many days may simply need a reboot. If uptime is short, rule this out and continue.

## Step 3 — Identify the heaviest processes
Determine whether the load is a known system process, a user application, or something unexpected. On the lab VM the top consumers were the homelab stack (Splunk, Elastic, MongoDB) — legitimate background tooling, not a fault.

## Step 4 — Check disk pressure
A volume above 85–90% causes slowness because Windows loses room for the pagefile and temp files. The lab VM's C: was at 82% — flagged as a yellow warning to monitor.

## Step 5 — Review recent System errors
An empty result means a clean log. Investigate any repeated errors before concluding.

## Step 6 — Remediate
- User application consuming resources: ask the user to close/restart it.
- Disk near full: run cleanup, clear temp files, check for large/old files.
- Unknown or suspicious process: do not kill it blindly — capture details and escalate.

## Step 7 — Validate and document
Re-run the health report and confirm the constrained resource has returned to baseline. Record findings, actions, and result.

## Escalation criteria
- A process with no known publisher or running from an unusual path (AppData, Temp).
- Resource usage stays high after remediation.
- Repeated System errors pointing to hardware or driver failure.
