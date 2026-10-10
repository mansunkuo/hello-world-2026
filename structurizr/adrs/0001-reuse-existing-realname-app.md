# 1. Reuse the agent's existing real-name app as the registration entry point

Date: 2026-10-07

## Status

Accepted

## Context

The agent wants to launch preorder lotteries at the lowest possible cost. Buyers already use the agent's real-name app, which already handles login, real-name verification and push notifications.
Building our own buyer app would mean rebuilding login and real-name verification, going through app-store review, and asking buyers to install yet another app.

## Decision

Registration, result lookup and pickup-store selection all live inside the agent's existing real-name app. We provide only the API and build no buyer app.
The real-name app forwards each request together with the real-name credential it issued; we verify the credential and do not repeat real-name verification.

We considered but did not choose:
- Building our own buyer app: the most flexible screens, but expensive, it requires rebuilding real-name verification, and buyers would have to install another app.

## Consequences

- Upside: no buyer app and no real-name verification to build, so development cost and time to launch drop sharply; buyers do not need another app.
- Downside: the registration screens and our schedule are bound to the real-name app's release cycle, so we must coordinate with the agent's app team.
- Downside: we depend on the real-name app's availability and credential format, and must adapt whenever the format changes.
- Later: if the campaign rules become complex and need more flexible screens, reconsider building our own buyer app.
