# Playbook: Account Lockout / Repeated Failed Logons

**Ticket type:** User account locked, or locking repeatedly
**Severity:** Low–Medium (escalates if brute-force is suspected)
**Target response:** 15 minutes

## Step 1 — Validate
Confirm which account is affected and the user's recent context: password change, new device, mapped drives, scheduled tasks. Determine whether the lockout is isolated or recurring.

## Step 2 — Confirm the lock state
For a local account, run `net user <username>` and look at the Account active line — `Locked` confirms the lockout. Also note Last logon; an account that has never logged on successfully but is being attacked is a red flag.

## Step 3 — Pull the failed logon events
Failed logons are Event ID 4625 in the Security log. Group events by timestamp. Failures clustered tightly in time belong to the same incident; isolated older events are usually unrelated noise.

## Step 4 — Identify the targeted account(s)
The account name is stored in the event's structured data, not the summary. Extract it from `Properties[5]`, which is the Target Account Name. This tells you exactly which accounts were hit.

## Step 5 — Triage: attack or user error?

| Indicator | Leans user error | Leans brute-force |
|-----------|------------------|-------------------|
| Time between attempts | Seconds-to-minutes apart, irregular | Very rapid, regular |
| Account history | Normally used, recent password change | Never logged on / dormant |
| Source | Single known device | Unknown or multiple sources |

On the lab VM: three failures against `jdoe` in 75 seconds, on an account with no prior successful logon — inconsistent with a human typo, consistent with a scripted attempt.

## Step 6 — Remediate
Unlock the local account with `net user <username> /active:yes` and verify it reads `Yes`. For a real user, also reset the password and require change at next logon, communicating the temp password through a secure channel only.

## Step 7 — Document and escalate if needed
Record the account, number and timing of failures, source, your triage conclusion, and the action taken. If brute-force indicators are present or the pattern repeats, escalate to security.

## Reference — configuring the lockout policy
Set the observation window first, then the duration, then the threshold:

    net accounts /lockoutwindow:5
    net accounts /lockoutduration:5
    net accounts /lockoutthreshold:3

Note: setting lockoutduration shorter than lockoutwindow raises System error 87 (parameter is incorrect). Set the window first, then the duration.
