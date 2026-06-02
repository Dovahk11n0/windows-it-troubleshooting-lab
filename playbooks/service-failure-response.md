# Playbook: Service Failure (e.g. Printing Stopped)

**Ticket type:** A feature stopped working (printing, updates, etc.)
**Severity:** Medium
**Target response:** 20 minutes

## Step 1 — Translate the symptom to a service
Map the user's complaint to the Windows service responsible. "I can't print" maps to the Print Spooler (`Spooler`). Don't restart anything yet.

## Step 2 — Detect stopped automatic services
Instead of guessing, surface every service that should be running but isn't:

    Get-Service | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' }

A service set to Automatic but currently Stopped is a genuine anomaly. On the lab VM this returned four results: `edgeupdate`, `MapsBroker`, `Spooler`, `sppsvc`.

## Step 3 — Correlate to the right service
Not every stopped automatic service is the problem — several are trigger-start and stopped by design. Match the user's symptom (printing) to the culprit (`Spooler`) and ignore the unrelated noise.

## Step 4 — Inspect the service in detail
`Get-Service` gives a fast status; `Win32_Service` (CIM) adds depth — notably `StartName`, the account the service runs under. A wrong or expired service account is a common reason a service won't start. Here it was `LocalSystem`, which is correct.

## Step 5 — Check the System log for cause
Look for events explaining why the service stopped. Note: Windows 10 Home logs manual service stops with less detail than Windows Server (which records Event ID 7034 for unexpected stops and 7036 for state changes). If no crash event exists, document that the stop appears clean rather than a fault.

## Step 6 — Restart and validate
Restart the service with `Start-Service Spooler`, then confirm `Status` returns to `Running` and that printing works.

## Escalation criteria
- Service fails to start after the restart attempt.
- System log shows a crash loop (repeated stop events within minutes).
- Service is third-party and needs vendor support.
