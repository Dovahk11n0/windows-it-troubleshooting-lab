# Windows IT Troubleshooting & PowerShell Automation Lab

A hands-on lab demonstrating real Help Desk / IT Support troubleshooting workflows on Windows using PowerShell. Each scenario reproduces a common support ticket, diagnoses it with native Windows tooling, and documents the resolution the way it would be recorded in a real ticketing system.

**Author:** Diago Gonzalez · [github.com/Dovahk11n0](https://github.com/Dovahk11n0)

---

## Why this lab exists

Most entry-level IT tickets fall into a handful of categories: something is slow, a service stopped working, or a user can't log in. This lab takes three of those tickets and works each one end to end — not by memorizing commands, but by following the diagnostic reasoning a technician actually uses: validate the symptom, gather evidence, find the root cause, remediate, and document.

Every output in this lab is real, captured from a live Windows 10 VM. Nothing is mocked.

---

## Environment

| Component | Detail |
|-----------|--------|
| Host | Physical PC running Windows 10 Pro |
| Hypervisor | Oracle VirtualBox |
| Guest VM | Windows 10 Home (standalone / WORKGROUP) |
| Shell | Windows PowerShell 5.1 |
| Logging | Windows Event Log (System, Security) |
| Tools | Get-CimInstance, Get-Process, Get-Service, Get-WinEvent, net accounts, net user, New-LocalUser |

> **Note on environment:** The guest VM runs Windows 10 Home, which has no Active Directory and limited account-management consoles. All user management in this lab uses **local accounts** via the `LocalAccounts` PowerShell module. A domain-based scenario (Scenario 3) is documented as a planned extension once a Windows Server VM is added.

---

## Scenarios

| # | Scenario | Skills demonstrated | Status |
|---|----------|--------------------|--------|
| 1 | System Health Report | Performance triage, CIM/WMI, process & disk analysis, event logs | Complete |
| 2 | Service Failure Diagnostic | Service management, automatic anomaly detection, layered diagnostics | Complete |
| 3 | Active Directory User Management | AD account lifecycle (create/disable/unlock) | Planned — needs Windows Server VM |
| 4 | Failed Logon Report | Account management, lockout policy, Security log analysis, brute-force vs user-error triage | Complete |

---

## Scenario 1 — System Health Report

**Ticket:** *"My computer is really slow, I can't work."*

A vague user complaint that has to be translated into measurable data. The `Get-SystemHealthReport.ps1` script collects a first-response snapshot of the system: uptime, top CPU and memory consumers, disk usage, and recent System-log errors — everything a Tier 1 technician checks before taking any action.

**Key insight:** A single script produces a repeatable, exportable baseline. Running six commands by hand on every machine doesn't scale; a script does.

**Findings on the test VM:** Resource usage was dominated by the lab's own homelab stack (Splunk `splunkd`, Elastic `fleet-server` / `filebeat`, `mongod`) rather than any fault. Drive C: sat at 82% (approaching the 85–90% warning threshold). No critical System errors in the prior 24 hours. The "slowness" was explained by background tooling, not a malfunction.

- Script: `scripts/Get-SystemHealthReport.ps1`
- Playbook: `playbooks/high-cpu-response.md`

---

## Scenario 2 — Service Failure Diagnostic

**Ticket:** *"I can't print anything."*

Printing in Windows depends on the Print Spooler service. But instead of assuming which service is at fault, this scenario uses an automatic detection approach: find **every** service that is set to start automatically but is currently stopped — a real anomaly — and then correlate the user's symptom to the right one.

```powershell
Get-Service | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' }
```

**Key insight:** Not every stopped service is a problem. The detection surfaced four stopped automatic services (`edgeupdate`, `MapsBroker`, `Spooler`, `sppsvc`), but only the Spooler matched the user's symptom. The others are trigger-start services that are stopped by design. Filtering signal from noise is the actual skill.

Diagnosis was layered: `Get-Service` for a quick status check, then `Get-CimInstance Win32_Service` for deeper detail (confirming the service runs under `LocalSystem`). The Spooler was restarted and validated back to `Running`.

- Playbook: `playbooks/service-failure-response.md`

---

## Scenario 4 — Failed Logon Report

**Ticket:** *"A user account keeps locking itself. Every time I unlock it, it locks again within minutes."*

This is the most valuable scenario because the same symptom has two very different causes: a benign one (an old cached password retrying somewhere) or a malicious one (a brute-force attempt). The technician's job is to tell them apart from the evidence.

The scenario was reproduced with real data, end to end:

1. Created three local users with PowerShell (`New-LocalUser`)
2. Configured an account lockout policy (`net accounts`) — lock after 3 attempts, 5-minute duration
3. Generated **real** failed logons against one account until it actually locked
4. Detected and analyzed the failures via **Event ID 4625** in the Security log
5. Extracted the targeted account names directly from the event data
6. Triaged the pattern, then unlocked and documented

**Key insight:** Three failures against `jdoe` in 75 seconds — on an account that had never had a successful logon — is inconsistent with a human typo and points to a scripted/brute-force pattern. Older 4625 events from a different date (`GoldRoguer`) were correctly identified as unrelated noise. Reading timestamps to group events into a single incident is core to the analysis.

This scenario is where Help Desk overlaps with SOC work: reading the Security log and reasoning about whether an event is a threat.

- Playbook: `playbooks/locked-account-response.md`

---

## Repository structure

```
windows-it-troubleshooting-lab/
├── README.md
├── scripts/
│   └── Get-SystemHealthReport.ps1
├── playbooks/
│   ├── high-cpu-response.md
│   ├── service-failure-response.md
│   └── locked-account-response.md
├── evidence/
│   └── findings.md
├── screenshots/
│   └── (captured terminal evidence)
└── references/
    └── sources.md
```

---

## What I learned

- **Windows internals via CIM/WMI** — querying `Win32_OperatingSystem` and `Win32_Service` to pull system state programmatically instead of clicking through the GUI.
- **The PowerShell pipeline** — chaining `Get-* | Where-Object | Sort-Object | Select-Object` to filter and shape data.
- **Event log analysis** — using `Get-WinEvent` with `-FilterHashtable`, and extracting structured fields (like the target account in a 4625 event) from the event properties.
- **Security policy configuration** — setting account lockout thresholds with `net accounts`, including resolving a real dependency error (System error 87, where lockout duration can't be shorter than the observation window).
- **Diagnostic reasoning** — the difference between "a thing is stopped" and "a thing is stopped that shouldn't be," and correlating a user symptom to the right root cause.
- **Honest documentation** — recording what the evidence actually showed, including when the Event Log didn't contain the expected entry, rather than forcing a tidy story.

---

## References

See `references/sources.md` for Microsoft documentation on every cmdlet and Event ID used.

