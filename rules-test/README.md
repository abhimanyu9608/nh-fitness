# Firestore rules tests

Checks every allow/deny case in `../firestore.rules` (PRD section 9) against the
Firebase Firestore emulator.

## Requirements

- Node.js 20 or newer (the tests use the built-in `node --test` runner)
- Java 11 or newer — the Firestore emulator is a Java program

## Run

```bash
cd rules-test
npm install
npm test
```

`npm test` starts the emulator, runs the tests against it and shuts it down
again. Nothing touches the real `nh-fitness-8a972` project: the emulator is
local and the project id is only a label.

To poke at the data by hand instead:

```bash
npm run emulator      # then open the Emulator UI link it prints
```

## What is covered

One `describe` block per `match` in the rules:

| Block | Cases |
|---|---|
| `admins/{uid}` | self read, other read, admin read, writes always denied |
| `users/{uid}` | self/admin read, the exact create shape, member-editable fields only, delete denied |
| `plans` | public read, admin-only write |
| `settings` | public read, admin-only write |
| `paymentRequests` | own read, price/UTR/total checks on create, admin-only review |
| `memberships` | own read, admin-only write |
| `classes` | active member reads published only, admin reads drafts |
| `announcements` | public read, admin-only write |

## Note on what rules cannot do

Two things in the PRD are deliberately *not* enforced here, because rules
cannot express them (PRD section 9, Notes):

- **One pending request at a time** (PAY-1) — checked in the app. The admin sees
  duplicates anyway.
- **A fake UTR** — no rule can tell a real UPI reference from an invented one.
  That is exactly why a human approves every payment.
