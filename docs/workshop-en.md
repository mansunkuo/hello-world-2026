# C4 Architecture Workshop: Toy Preorder Lottery Service

A hands-on [C4 Model](https://c4model.com) exercise. You will model **an agent's toy preorder lottery service** in six steps and end up with five consistent diagrams written in one text file, then learn manual layout. Finally you will write one key decision up as an ADR (Architecture Decision Record).

You describe what each diagram should say; **opencode** writes the [Structurizr DSL](https://docs.structurizr.com/dsl/language) and checks its own work. You don't need to memorize the syntax, but you will read it, so a cheat sheet and troubleshooting table are at the end.

> **Scenario.** You are the system vendor for an agent. The agent **already has a real-name verification app** where buyers log in and complete real-name verification, and it already has a **store system**. The agent wants to run toy preorders at the **lowest possible cost**:
>
> - Operators set each preorder campaign's **period** and the **total number of toys each buyer may enter for**;
> - Buyers register for the items they want to enter during the campaign period;
> - When the campaign **closes, a lottery** picks the winners;
> - Winners choose which **store** they want to pick their goods up from.
>
> Our job is to **plug all of this into the existing real-name app**, not to build a separate buyer app, and not to rebuild the store system.

---

## Contents

- [The Six Steps](#the-six-steps)
- [What We Verify](#what-we-verify)
- [Before the Workshop](#before-the-workshop)
- [Step 1: One Slide That Draws the Boundary](#step-1-one-slide-that-draws-the-boundary)
- [Step 2: What Do We Build Ourselves?](#step-2-what-do-we-build-ourselves)
- [Step 3: Open Up the API](#step-3-open-up-the-api)
- [Step 4: The Sequence of One Campaign](#step-4-the-sequence-of-one-campaign)
- [Step 5: Where Does Everything Run?](#step-5-where-does-everything-run)
- [Step 6: Remove autoLayout and Arrange It Yourself](#step-6-remove-autolayout-and-arrange-it-yourself)
- [ADR: Write Down the "Why"](#adr-write-down-the-why)
- [Wrap-up](#wrap-up)
- [Troubleshooting](#troubleshooting)
- [DSL Cheat Sheet (to read, not to write)](#dsl-cheat-sheet-to-read-not-to-write)
- [References](#references)

---

## The Six Steps

C4 is not "draw five diagrams". It is **answering a series of questions in order, where each one zooms into a box of the previous diagram**. The five diagrams live in one file, `structurizr/workspace.dsl`. Each step only adds to it; you never rewrite it or delete earlier diagrams.

| Step | Diagram | The question it answers |
| --- | --- | --- |
| 1 | System Context | Who uses this system? What does it depend on? What is not ours? |
| 2 | Containers | What do we write, what do we reuse, what do we run? |
| 3 | Components | Where does a new business rule (e.g. campaign period, per-buyer limit) go? |
| 4 | PreorderFlow (dynamic view) | What happens, in order, during a whole preorder campaign? |
| 5 | Deployment | Where does everything actually run? |
| 6 | (manual layout) | What do you do when the automatic layout turns into a mess? |
| ADR | Decision record (text, no diagram) | Why did we decide this? What else did we consider? |

Diagrams answer "what"; an ADR answers "**why**". Each step ends with one **ADR candidate**: a decision you just made in the diagram. **Don't discuss it now.** Jot down one line in your notes; at the end you will pick one and write it up as an ADR.

Every step runs the same loop:

```
paste the prompt into opencode  →  the agent validates and shows the new diagram  →  you check the "Verify" items  →  git commit
```

| Command | Purpose |
| --- | --- |
| `make up` | Start the interactive viewer at <http://localhost:8080> (reload the browser to pick up changes) |
| `make validate` | Check that the file parses |
| `make export` | Export a shareable static site to `structurizr/static-site/` |
| `make down` | Stop the viewer |

## What We Verify

Each step's "Verify" section has only 2 or 3 items, on top of these three baselines that apply to every step:

| Baseline | Why | How to confirm |
| --- | --- | --- |
| The file parses | A broken file blocks everything after it | The agent reports `validate` returned `OK` (or run `make validate` yourself) |
| No blank boxes | A box without a description teaches nobody anything | The `inspect` report has no "missing a description" |
| Earlier diagrams are not broken | The five diagrams are different views of one model | Click through the earlier diagrams in the navigation; their boxes and lines are unchanged |

You can **ignore** the other complaints in the quality report (missing protocol, missing documentation): people and in-process calls have no protocol to fill in, and documentation is out of scope. "Missing decisions" is handled in the ADR section at the end; once an ADR is attached, that complaint should disappear.

---

## Before the Workshop

You need this repo and [Docker](https://www.docker.com/) or [Podman](https://podman.io/). Run all commands from the repo root; the full toolchain is described in the [README](README.md).

**1. Structurizr MCP server** (lets the agent check its own work)

```bash
# Hosted by Structurizr
opencode mcp add structurizr --url https://mcp.structurizr.com/mcp

# Or run it locally (bound to localhost only, works offline; prefer this for real client projects so the model is not sent to a third party)
docker run -d --rm -p 127.0.0.1:3000:3000 -e PORT=3000 structurizr/mcp -dsl -mermaid
opencode mcp add structurizr --url http://localhost:3000/mcp
```

You can finish without MCP: the agent follows the existing style and you validate with `make validate`. No containers and no MCP? Download the [Structurizr CLI](https://docs.structurizr.com/cli) (needs Java) and run `structurizr.sh validate -workspace structurizr/workspace.dsl`.

**2. The rules file `AGENTS.md`**

Each prompt contains only what is unique to that step. The rules that are the same every time (never rename, don't touch earlier diagrams, every element needs a description, where the protocol goes, validate then inspect before finishing…) live in `AGENTS.md` at the repo root, which opencode reads at the start of a conversation. It is written for the agent, so you don't need to memorize it.

```markdown
# Structurizr modeling rules

This project models a system as C4 diagrams in Structurizr DSL. Everything lives in one file: `structurizr/workspace.dsl`.

## Scope
- Only edit `structurizr/workspace.dsl` (and `structurizr/adrs/` when I ask for a decision record).
- Do only what this step asks. Do not add boxes, relationships or views that were not requested.
- Never rename existing elements (title or identifier). Do not touch existing views unless the step explicitly asks.
- When I say "do not edit files yet", only propose; do not edit.

## Syntax
- Include `configuration { scope softwaresystem }`.
- The opening `{` goes at the end of the declaration line, never on its own line.
- View keys may only contain `a-zA-Z0-9_-`. Titles may be in any language.
- `autoLayout` always needs a direction: `autoLayout lr`.
- A system context or container view with `include *` only shows elements directly connected to the system in scope. If a step says a person must appear even though they reach the system through an external system, add `include <person>` explicitly.

## Content
- Every element (person, softwareSystem, container, component, deploymentNode) needs a one-sentence description of its responsibility.
- Containers and components need a technology.
- Write relationships as verb phrases. For machine-to-machine relationships, put the protocol in the last quoted string: `a -> b "verb phrase" "HTTPS"`. Never put the protocol inside the verb phrase.
- People and in-process calls have no protocol; leave it out.
- Systems we do not own get the tag `"External System"` (keep this exact tag).
- In the first step, define one `styles` entry for the tag `"External System"` only (`#999999`, white text). The base colors for people, systems, containers and components come from the theme.
- Reference themes by their raw GitHub URL only. Never use `theme default`, never use a bare theme name (it does not resolve in this setup), and never create theme files.
- Default theme (base colors for people, systems, containers and components): `theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json`
- Only in the deployment step, switch to `themes <default theme URL> <cloud theme URL>` using the cloud provider the user chose. Cloud theme URLs follow `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/<directory>/theme.json`, where `<directory>` is `amazon-web-services-2025.07`, `microsoft-azure-2025.11`, `google-cloud-platform-2025.09`, `oracle-cloud-infrastructure-2023.04` or `kubernetes`. Pin to the release tag, never `main`.
- In deployment views, tag nodes with the exact tags defined by the cloud theme (see https://playground.structurizr.com/themes). For AWS, for example: `Amazon Web Services - Region`, `Amazon Web Services - Fargate`, `Amazon Web Services - RDS`, `Amazon Web Services - EventBridge`.
- In deployment views, relationships between containers appear automatically from the model. Do not redraw them between machines; only add relationships the model does not already have.
- Architecture decision records (ADRs) go in `structurizr/adrs/` in adr-tools Markdown format (title, Date, Status, Context, Decision, Consequences). Use lowercase English file names with hyphens, e.g. `0001-reuse-existing-realname-app.md` (non-ASCII file names fail to load in some environments), and attach them to the relevant element. An ADR must name the alternatives that were not chosen and at least one downside.

## Before you finish
- Run `validate` and wait for `OK` before saying you are done.
- Run `inspect` and report every finding to me.
- Use `parse` to count the boxes and lines of the new view; do not guess.
- Show me the new diagram.
- If you cannot reach the MCP server, say so honestly instead of claiming success.
```

If your agent does not read it automatically, paste the whole file as the first message of a new conversation.

**3. Themes**

In this workshop **themes are always referenced by GitHub URL**. Don't use `theme default`: it downloads the theme from the Structurizr cloud service, which reached end of life on 2026-09-30, so `make validate` would exit 1. Don't use the bare folder-name shorthand either (for example `amazon-web-services-2025.07`); it does not load in our environment.

- **Default theme**, which provides the base colors for people, systems, containers and components:

  ```text
  theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
  ```

- **Cloud theme** (icons for the Step 5 deployment diagram) must be used together with the default theme, so switch to the plural `themes`. The singular `theme` accepts only one:

  ```text
  themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
  ```

**All theme URLs** (to switch cloud, replace the second URL on the `themes` line):

| Theme | URL |
| --- | --- |
| Default theme (base colors for people, systems, containers, components) | `https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json` |
| AWS 2025.07 (latest) | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json` |
| AWS 2023.01 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2023.01/theme.json` |
| AWS 2022.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2022.04/theme.json` |
| AWS 2020.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2020.04/theme.json` |
| Azure 2025.11 (latest) | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2025.11/theme.json` |
| Azure 2024.07 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2024.07/theme.json` |
| Azure 2023.01 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2023.01/theme.json` |
| Azure 2021.01 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2021.01/theme.json` |
| Azure 2020.07 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2020.07/theme.json` |
| Azure 2019.09 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2019.09/theme.json` |
| GCP 2025.09 (latest, only about 40 tags) | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/google-cloud-platform-2025.09/theme.json` |
| GCP v1.5 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/google-cloud-platform-v1.5/theme.json` |
| Oracle Cloud 2023.04 (latest) | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/oracle-cloud-infrastructure-2023.04/theme.json` |
| Oracle Cloud 2021.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/oracle-cloud-infrastructure-2021.04/theme.json` |
| Oracle Cloud 2020.04 | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/oracle-cloud-infrastructure-2020.04/theme.json` |
| Kubernetes | `https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/kubernetes/theme.json` |

The default theme URL points at the `master` branch; to pin a version, replace `master` with a commit, for example `67da2b503abc708f941e5aa2ea35dd553f742c3a`. The cloud themes are already pinned to the release tag `v2026.09.19`; don't change that to `main`, or your diagrams will change whenever the themes are updated.

**Icon tags differ per theme.** AWS uses `Amazon Web Services - Fargate`, Azure uses `Microsoft Azure - Container Instances`, and GCP's tags are different again. Look up the exact strings in the [theme browser](https://playground.structurizr.com/themes).

> The URL form needs network access: the viewer reads the themes and icons from GitHub when it loads. If the venue's network is unreliable, you can download the default theme as a local file as a fallback (`curl -o structurizr/theme.json https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json`, then write `theme "theme.json"` in the DSL), but the cloud icons still need the network. This workshop also does not require `STRUCTURIZR_THEMES`; it only helps with the folder-name shorthand.

**4. Version control**

Everything is under git. Commit after every step: `git add structurizr && git commit -m "step 1"`; `git diff` then shows exactly what the step added. To start over: `git checkout structurizr/workspace.dsl`.

---

## Step 1: One Slide That Draws the Boundary

> The product manager has a short meeting with their boss: who uses this preorder lottery system? What does it depend on? What is not our responsibility?
>
> The trap: the agent **already has** the real-name app and the store system. We **reuse and call** them; we don't rebuild them. And don't talk about PostgreSQL at this level; draw only people, our system, and the systems we don't own.

### Prompt

```text
Read structurizr/workspace.dsl, replace the sample with a Level 1 system context diagram for this project, name the view "SystemContext", and make it the only view in the file.

Scenario: an agent wants to run a toy preorder lottery at the lowest possible cost. Operators set each campaign's period and the total number of toys each buyer may enter for; buyers register for the toys they want in the agent's existing real-name app (the app handles real-name verification); when the campaign closes, the system draws the winners and notifies them through the app's push notifications; winners then choose which store to pick up from, and we send the winner list and pickup stores to the agent's existing store pickup system.
We don't build a buyer app and we don't build the store system. The buyer does not connect directly to our system, but must appear in the diagram (they use our features through the real-name app).

External systems: the agent's real-name app and the store pickup system already exist, they are not ours. Tag them "External System" and show them in grey, to distinguish them from our own system (blue).
Make this workspace use the official Structurizr default theme, referenced by URL: https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json (it provides the base colors for people and systems). Do not use theme default.
Do not mention any technology names at this level.
```

### Verify

- [ ] **5 boxes, 5 lines**: Buyer, Operator, Preorder Lottery System, and the two external systems (real-name app, store pickup system); no technology names anywhere in the diagram (if React or PostgreSQL show up, you drew a container diagram).
- [ ] **The two external systems are grey, our own system is blue, and people are dark blue.** From this diagram on, "who is ours and who isn't" is visible at a glance, and every later diagram keeps it.

> **ADR candidate 1: reuse the real-name app as the registration entry point instead of building a buyer app.** — Just jot down one line in your notes; don't discuss it yet.

<details>
<summary>Reference answer: complete <code>workspace.dsl</code> after Step 1</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store."
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> preorderSystem "Forwards preorder requests (already real-name verified)"
        preorderSystem -> realnameApp "Pushes lottery result notifications"
        operator -> preorderSystem "Sets up preorder campaigns and lottery rules"
        preorderSystem -> storeSystem "Sends the winner list and pickup stores"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 2: What Do We Build Ourselves?

> The boss asks: "Which parts do we write ourselves, and which do we reuse?" Open up the "Preorder Lottery System" box. **A container is "a unit that can be deployed independently"** (it has its own process and can be restarted on its own); it is not the same thing as a Docker container.

### Prompt

```text
Read structurizr/workspace.dsl and add a Level 2 container diagram named "Containers". Do not touch SystemContext.

Open up "Preorder Lottery System" into 4 independently deployable containers:
  Admin Web ([your preferred frontend framework, e.g. React], used by operators to set up campaigns)
  Preorder API ([your preferred backend language and framework, e.g. Node.js / Express], receives the registrations and pickup-store choices forwarded by the real-name app, and is also used by the admin web)
  Lottery Job (a scheduled job in [the same backend language]; when a campaign closes it draws the winners and asks the real-name app to push the results)
  Preorder Database ([a database you know, e.g. PostgreSQL])

Move the relationships that used to point at the whole "Preorder Lottery System" onto the containers that really own them, and label machine-to-machine relationships with the protocol.
The real-name app and the store pickup system stay outside the system box; the buyer must still appear in the diagram.
```

> Replace the [ ] parts with the technologies your team actually knows (the reference answer uses React, Node.js, PostgreSQL). The agent puts them on the containers, and the Step 3 components and the Step 5 deployment reuse them; if you change the database, change the managed service in Step 5 too.

### Verify

- [ ] **The system box holds 4 containers, and the two external systems are outside it.** If the real-name app is drawn inside, the boundary means nothing.
- [ ] **No arrow still points at the whole "Preorder Lottery System".** The old relationships were **moved** onto the containers, not left behind next to them.
- [ ] The navigation shows 2 diagrams, and `SystemContext` looks the same as before.

> Structurizr **by default** infers relationships between the parent elements from the relationships between their children (implied relationships). No setting is needed: the lines you don't redraw in Steps 3 to 5 rely on it. Further reading: [Implied relationships](https://docs.structurizr.com/dsl/cookbook/implied-relationships/).
>
> **ADR candidate 2: run the lottery as a batch scheduled job at closing time**, instead of deciding at registration time. — Just jot down one line in your notes; don't discuss it yet.

<details>
<summary>Reference answer: what changed in this step (diff)</summary>

```diff
@@ -6,3 +6,8 @@
 
-        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store."
+        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
+            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
+            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API"
+            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
+            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
+        }
         realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
@@ -11,6 +16,9 @@
         buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
-        realnameApp -> preorderSystem "Forwards preorder requests (already real-name verified)"
-        preorderSystem -> realnameApp "Pushes lottery result notifications"
-        operator -> preorderSystem "Sets up preorder campaigns and lottery rules"
-        preorderSystem -> storeSystem "Sends the winner list and pickup stores"
+        realnameApp -> preorderApi "Forwards preorder requests (with the real-name credential)" "HTTPS"
+        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
+        adminWeb -> preorderApi "Reads and writes campaign settings" "HTTPS"
+        preorderApi -> preorderDb "Reads and writes campaigns, registrations, lottery results and pickup stores" "SQL"
+        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
+        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
+        preorderApi -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
     }
@@ -24,2 +32,7 @@
             include *
+            include buyer
+            autoLayout lr
+        }
+        container preorderSystem "Containers" {
+            include *
             include buyer
```

</details>

<details>
<summary>Reference answer: complete <code>workspace.dsl</code> after Step 2</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API"
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> preorderApi "Forwards preorder requests (with the real-name credential)" "HTTPS"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> preorderApi "Reads and writes campaign settings" "HTTPS"
        preorderApi -> preorderDb "Reads and writes campaigns, registrations, lottery results and pickup stores" "SQL"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
        preorderApi -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 3: Open Up the API

> A new engineer asks: "Where do the rules about the campaign period and each buyer's total limit go?" The container diagram only says "the Preorder API talks to the database"; it doesn't say **which part** of the API is responsible. Open up the "Preorder API". This is the lowest level in this workshop (C4 has a fourth level, Code, but below this it becomes a class diagram, and you can usually just read the code).

### Prompt

```text
Read structurizr/workspace.dsl and add a Level 3 component diagram named "Components". Do not touch the first two diagrams.

Open up "Preorder API" into 4 components:
  Credential Guard (verifies the real-name credential issued by the real-name app)
  Campaign Rules Service (the rules about the campaign period and each buyer's total entry limit)
  Registration Service (buyers register for the toys they want, and look up results)
  Pickup Service (winning buyers choose a pickup store, and the store pickup system is notified)
The components use the same language and framework as the Preorder API.
Every buyer request coming from the real-name app must pass through Credential Guard first; it is the only entry point. The admin web only calls Campaign Rules Service (operator login is outside this diagram).
Move the relationships that used to point at the whole "Preorder API" onto the components that really own them.
```

### Verify

- [ ] **The real-name app has exactly one line into the API, and it goes into Credential Guard.** If it also connects directly to another component, you have drawn a back door that skips credential verification.
- [ ] **No arrow still points at the whole "Preorder API"**; the rules for "campaign period" and "per-buyer entry limit" live in **Campaign Rules Service** only, and Registration Service looks them up rather than deciding itself. Can you answer: "If we add a rule (say, at most 3 items per campaign), where do we change it?"
- [ ] The navigation shows 3 diagrams, and the first two have no boxes or lines added or removed.

> Four components is the ceiling; adding more means drawing a class diagram. Keeping the rules in one place is a trade-off, not the one right answer: being able to explain your reasoning is enough.
>
> **ADR candidate 3: keep the campaign rules (period, per-buyer limit) in Campaign Rules Service**, rather than scattering them across the registration and pickup services. — Just jot down one line in your notes; don't discuss it yet.

<details>
<summary>Reference answer: what changed in this step (diff)</summary>

```diff
@@ -8,3 +8,8 @@
             adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
-            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API"
+            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
+                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
+                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
+                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
+                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
+            }
             lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
@@ -16,9 +21,15 @@
         buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
-        realnameApp -> preorderApi "Forwards preorder requests (with the real-name credential)" "HTTPS"
+        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
+        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
+        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
+        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
+        pickupService -> campaignService "Looks up the available pickup stores"
         operator -> adminWeb "Sets up preorder campaigns and lottery rules"
-        adminWeb -> preorderApi "Reads and writes campaign settings" "HTTPS"
-        preorderApi -> preorderDb "Reads and writes campaigns, registrations, lottery results and pickup stores" "SQL"
+        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
+        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
+        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
+        pickupService -> preorderDb "Saves pickup stores" "SQL"
+        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
         lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
         lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
-        preorderApi -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
     }
@@ -39,2 +50,6 @@
             autoLayout lr
+        }
+        component preorderApi "Components" {
+            include *
+            autoLayout lr
         }
```

</details>

<details>
<summary>Reference answer: complete <code>workspace.dsl</code> after Step 3</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
            }
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
        pickupService -> campaignService "Looks up the available pickup stores"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
        pickupService -> preorderDb "Saves pickup stores" "SQL"
        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 4: The Sequence of One Campaign

> The first three diagrams are "everything at once" views; they can't express "first this, then that, finally this". This **dynamic view** draws one concrete journey through a whole campaign: the operator sets it up, buyers register, the lottery runs at closing, results are pushed, winners choose a store. It cuts across all levels and **changes nothing in the model**.

### Prompt

```text
Read structurizr/workspace.dsl and add a dynamic view named "PreorderFlow": what happens, in order, during a whole preorder campaign — the operator sets up the campaign, buyers register during the period, the lottery runs at closing, results are pushed, winning buyers choose a pickup store, all the way until the store pickup system receives the list.
Use only elements that already exist in the file and do not change the model at all; number the arrows consecutively from 1 in time order.
```

### Verify

- [ ] **Arrow numbers are consecutive (the reference answer is 1 to 9) and the order makes sense**: set up campaign → register → lottery at closing → push → choose store → send to store system.
- [ ] **The model is unchanged.** `git diff` shows only one new view, and no new elements or relationships.

> **ADR candidate 4: push the lottery results through the real-name app**, instead of integrating SMS separately. — Just jot down one line in your notes; don't discuss it yet.

<details>
<summary>Reference answer: what changed in this step (diff)</summary>

```diff
@@ -55,2 +55,14 @@
         }
+        dynamic preorderSystem "PreorderFlow" "The full flow of a preorder campaign, from setup and registration through the lottery to pickup stores." {
+            operator -> adminWeb "1. Operator sets the campaign period and per-buyer entry limit"
+            buyer -> realnameApp "2. Buyer registers for toys during the campaign"
+            realnameApp -> preorderApi "3. Forwards the registration (with real-name credential)" "HTTPS"
+            preorderApi -> preorderDb "4. Checks period and limit, saves the registration" "SQL"
+            lotteryJob -> preorderDb "5. At closing, reads registrations, draws, saves results" "SQL"
+            lotteryJob -> realnameApp "6. Asks the app to push the results" "HTTPS"
+            buyer -> realnameApp "7. A winning buyer chooses a pickup store"
+            realnameApp -> preorderApi "8. Forwards the store choice (with real-name credential)" "HTTPS"
+            preorderApi -> storeSystem "9. Sends the winner list and pickup stores" "HTTPS"
+            autoLayout lr
+        }
         styles {
```

</details>

<details>
<summary>Reference answer: complete <code>workspace.dsl</code> after Step 4</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
            }
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
        pickupService -> campaignService "Looks up the available pickup stores"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
        pickupService -> preorderDb "Saves pickup stores" "SQL"
        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "The full flow of a preorder campaign, from setup and registration through the lottery to pickup stores." {
            operator -> adminWeb "1. Operator sets the campaign period and per-buyer entry limit"
            buyer -> realnameApp "2. Buyer registers for toys during the campaign"
            realnameApp -> preorderApi "3. Forwards the registration (with real-name credential)" "HTTPS"
            preorderApi -> preorderDb "4. Checks period and limit, saves the registration" "SQL"
            lotteryJob -> preorderDb "5. At closing, reads registrations, draws, saves results" "SQL"
            lotteryJob -> realnameApp "6. Asks the app to push the results" "HTTPS"
            buyer -> realnameApp "7. A winning buyer chooses a pickup store"
            realnameApp -> preorderApi "8. Forwards the store choice (with real-name credential)" "HTTPS"
            preorderApi -> storeSystem "9. Sends the winner list and pickup stores" "HTTPS"
            autoLayout lr
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
```

</details>

---

## Step 5: Where Does Everything Run?

> The on-call engineer asks: "At the moment a campaign closes, where does the lottery job actually run? What sits between it and the real-name app?" Place every container on real infrastructure and the distances show up by themselves: operators are in an office, the agent's existing systems are in another data center, and our code is in the cloud.

### Prompt

```text
Read structurizr/workspace.dsl and add a deployment view named "Deployment" (environment name "Production") showing where everything actually runs:

  Cloud Region ([the cloud provider and region you know, e.g. AWS ap-northeast-1, or the equivalent Azure or GCP region]): a managed container service runs the Preorder API; a scheduler triggers a container task that runs the Lottery Job; a managed database runs the Preorder Database (single availability zone, to save cost). Use that cloud's real service names (AWS example: ECS Fargate, EventBridge, RDS).
  Agent Office: an Operator PC that runs the Admin Web in a browser
  Agent Existing Systems: a Real-name App Service that runs the Agent Real-name App, and a Store Pickup System Host that runs the Store Pickup System

All three locations must appear in the same view, and every location and machine needs a one-sentence description.
Traffic between containers appears automatically from the model, so do not redraw it and do not add any machine-to-machine relationships.
Then attach that cloud's prebuilt Structurizr theme, always by URL, together with the default theme:
  AWS: https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
  Azure: https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/microsoft-azure-2025.11/theme.json
  GCP: https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/google-cloud-platform-2025.09/theme.json
and tag the cloud nodes with the icon tags the theme provides (tag names can be looked up at https://playground.structurizr.com/themes). Keep the original default theme.
Do not touch the other views or the model.
```

### Verify

- [ ] **3 locations, and every container has one running instance**; the Admin Web runs on the operator's PC in the office, the two external systems are in the agent's existing systems, and **only the Preorder API, Lottery Job and database are in the cloud**; the cloud nodes show the icons of the cloud you chose.
- [ ] **The lines that cross locations are visible**: Real-name App → Preorder API, Lottery Job → Real-name App, and Preorder API → Store Pickup System each go from one location to another. That crossing is the whole point of this diagram.
- [ ] The navigation shows 5 diagrams, and the first four are unchanged.

> **This diagram will very likely turn into a mess; that is expected** (the reference answer has 15 boxes and 6 lines, nested three levels deep: location → machine → instance). The cause and the fix are in the next step.
>
> The reference answer uses AWS; with Azure or GCP the node names and icon tags differ, but the structure is identical. See "Themes" in "Before the Workshop" for the theme URLs and how to look up tags. If the cloud nodes show no icon, first check that the theme URL is correct and that the viewer can reach GitHub.
>
> **Further reading:** the [theme browser](https://playground.structurizr.com/themes) (icons and tag names of every theme), and the [Themes documentation](https://docs.structurizr.com/ui/diagrams/themes).
>
> **ADR candidate 5: use a managed database in a single availability zone, and trigger the job with EventBridge running a Fargate task**, trading availability for low cost. — Just jot down one line in your notes; don't discuss it yet.

<details>
<summary>Reference answer: what changed in this step (diff)</summary>

```diff
@@ -34,2 +34,33 @@
         lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
+
+        production = deploymentEnvironment "Production" {
+            cloud = deploymentNode "Cloud Region" "Cloud services that we run ourselves." "AWS ap-northeast-1" {
+                tags "Amazon Web Services - Region"
+                ecs = deploymentNode "ECS Fargate" "Runs the Preorder API in containers without managing servers." "AWS Fargate" {
+                    tags "Amazon Web Services - Fargate"
+                    apiInstance = containerInstance preorderApi
+                }
+                scheduler = deploymentNode "EventBridge Scheduled Task" "Triggers the lottery job at the campaign's closing time." "AWS EventBridge + Fargate task" {
+                    tags "Amazon Web Services - EventBridge"
+                    jobInstance = containerInstance lotteryJob
+                }
+                rds = deploymentNode "RDS for PostgreSQL" "A managed relational database in a single availability zone to save cost." "PostgreSQL 16" {
+                    tags "Amazon Web Services - RDS"
+                    dbInstance = containerInstance preorderDb
+                }
+            }
+            office = deploymentNode "Agent Office" "Where the operators work." "Office network" {
+                browser = deploymentNode "Operator PC" "Opens the admin web in a browser." "Web browser" {
+                    adminInstance = containerInstance adminWeb
+                }
+            }
+            agentEnv = deploymentNode "Agent Existing Systems" "Existing systems that the agent operates itself; we only call them." "Agent data center" {
+                appHost = deploymentNode "Real-name App Service" "The agent's existing real-name app backend." "Existing system" {
+                    realnameInstance = softwareSystemInstance realnameApp
+                }
+                storeHost = deploymentNode "Store Pickup System Host" "The agent's existing store system." "Existing system" {
+                    storeInstance = softwareSystemInstance storeSystem
+                }
+            }
+        }
     }
@@ -67,2 +98,6 @@
         }
+        deployment * "Production" "Deployment" "Where each service actually runs in production." {
+            include *
+            autoLayout lr
+        }
         styles {
@@ -73,3 +108,3 @@
         }
-        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
+        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
     }
```

</details>

<details>
<summary>Reference answer: complete <code>workspace.dsl</code> after Step 5</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
            }
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
        pickupService -> campaignService "Looks up the available pickup stores"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
        pickupService -> preorderDb "Saves pickup stores" "SQL"
        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"

        production = deploymentEnvironment "Production" {
            cloud = deploymentNode "Cloud Region" "Cloud services that we run ourselves." "AWS ap-northeast-1" {
                tags "Amazon Web Services - Region"
                ecs = deploymentNode "ECS Fargate" "Runs the Preorder API in containers without managing servers." "AWS Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance preorderApi
                }
                scheduler = deploymentNode "EventBridge Scheduled Task" "Triggers the lottery job at the campaign's closing time." "AWS EventBridge + Fargate task" {
                    tags "Amazon Web Services - EventBridge"
                    jobInstance = containerInstance lotteryJob
                }
                rds = deploymentNode "RDS for PostgreSQL" "A managed relational database in a single availability zone to save cost." "PostgreSQL 16" {
                    tags "Amazon Web Services - RDS"
                    dbInstance = containerInstance preorderDb
                }
            }
            office = deploymentNode "Agent Office" "Where the operators work." "Office network" {
                browser = deploymentNode "Operator PC" "Opens the admin web in a browser." "Web browser" {
                    adminInstance = containerInstance adminWeb
                }
            }
            agentEnv = deploymentNode "Agent Existing Systems" "Existing systems that the agent operates itself; we only call them." "Agent data center" {
                appHost = deploymentNode "Real-name App Service" "The agent's existing real-name app backend." "Existing system" {
                    realnameInstance = softwareSystemInstance realnameApp
                }
                storeHost = deploymentNode "Store Pickup System Host" "The agent's existing store system." "Existing system" {
                    storeInstance = softwareSystemInstance storeSystem
                }
            }
        }
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "The full flow of a preorder campaign, from setup and registration through the lottery to pickup stores." {
            operator -> adminWeb "1. Operator sets the campaign period and per-buyer entry limit"
            buyer -> realnameApp "2. Buyer registers for toys during the campaign"
            realnameApp -> preorderApi "3. Forwards the registration (with real-name credential)" "HTTPS"
            preorderApi -> preorderDb "4. Checks period and limit, saves the registration" "SQL"
            lotteryJob -> preorderDb "5. At closing, reads registrations, draws, saves results" "SQL"
            lotteryJob -> realnameApp "6. Asks the app to push the results" "HTTPS"
            buyer -> realnameApp "7. A winning buyer chooses a pickup store"
            realnameApp -> preorderApi "8. Forwards the store choice (with real-name credential)" "HTTPS"
            preorderApi -> storeSystem "9. Sends the winner list and pickup stores" "HTTPS"
            autoLayout lr
        }
        deployment * "Production" "Deployment" "Where each service actually runs in production." {
            include *
            autoLayout lr
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
    }
}
```

</details>

---

## Step 6: Remove autoLayout and Arrange It Yourself

> Before a presentation you notice the Deployment diagram is a mess, with lines running over each other. Structurizr's automatic layout gets worse the deeper the nesting and the more lines cross boundaries. **Don't ask the agent to fix it.** Remove `autoLayout` and drag things yourself.

**Why is Deployment especially bad?** `autoLayout` first lays all boxes out as one flat graph, then draws each nested frame (locations, machines) around them. The Deployment diagram has the most and deepest frames, so they overlap most easily. (This is our reading of how Structurizr lays things out; please look at the diagram before and after removing `autoLayout` to confirm that it really is the cause.)

### How

**1. Ask the agent to remove that line (this one view only):**

```text
In structurizr/workspace.dsl, remove autoLayout from the "Deployment" view. Leave the other views as they are and do not change anything else.
```

**2. Reload <http://localhost:8080> and open Deployment.** With no layout information the boxes may be stacked on top of each other. That is normal; from here on you drag them yourself.

**3. Drag with the mouse.** Suggestion: first pull the three locations apart (Agent Office on the left, Cloud Region in the middle, Agent Existing Systems on the right), then adjust the machines and instances so lines don't cross.

**4. Positions are saved automatically into `structurizr/workspace.json`** (the DSL describes "what exists", `workspace.json` records "where it sits"). Check with `git status` that it changed, then commit it, so the positions travel with the version.

### Verify

- [ ] `git diff structurizr/workspace.dsl` shows **only one `autoLayout lr` line removed from the Deployment block**; the other four diagrams still use automatic layout.
- [ ] `git status` shows **`structurizr/workspace.json` changed**.
- [ ] After reloading the browser, **the positions are still there**.

> **How are the positions kept?** The x and y positions are not written in the DSL but in `workspace.json`; when the DSL is reloaded, Structurizr matches the old positions back by **element name** and **view key**. So once you have arranged a diagram, **don't casually rename elements or change view keys** (this is one reason `AGENTS.md` forbids renaming), or those positions are lost.
>
> To go back to automatic layout, add `autoLayout lr` back (manual positions are overwritten).
>
> **Further reading:** [Diagram editor](https://docs.structurizr.com/ui/diagrams/editor) (what else the editor can do) and [Manual layout](https://docs.structurizr.com/ui/diagrams/manual-layout) (how positions are stored, and why they are sometimes lost).

<details>
<summary>Reference answer: what changed in this step (diff)</summary>

```diff
@@ -100,3 +100,2 @@
             include *
-            autoLayout lr
         }
```

</details>

<details>
<summary>Reference answer: complete <code>workspace.dsl</code> after Step 6</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
            }
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
        pickupService -> campaignService "Looks up the available pickup stores"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
        pickupService -> preorderDb "Saves pickup stores" "SQL"
        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"

        production = deploymentEnvironment "Production" {
            cloud = deploymentNode "Cloud Region" "Cloud services that we run ourselves." "AWS ap-northeast-1" {
                tags "Amazon Web Services - Region"
                ecs = deploymentNode "ECS Fargate" "Runs the Preorder API in containers without managing servers." "AWS Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance preorderApi
                }
                scheduler = deploymentNode "EventBridge Scheduled Task" "Triggers the lottery job at the campaign's closing time." "AWS EventBridge + Fargate task" {
                    tags "Amazon Web Services - EventBridge"
                    jobInstance = containerInstance lotteryJob
                }
                rds = deploymentNode "RDS for PostgreSQL" "A managed relational database in a single availability zone to save cost." "PostgreSQL 16" {
                    tags "Amazon Web Services - RDS"
                    dbInstance = containerInstance preorderDb
                }
            }
            office = deploymentNode "Agent Office" "Where the operators work." "Office network" {
                browser = deploymentNode "Operator PC" "Opens the admin web in a browser." "Web browser" {
                    adminInstance = containerInstance adminWeb
                }
            }
            agentEnv = deploymentNode "Agent Existing Systems" "Existing systems that the agent operates itself; we only call them." "Agent data center" {
                appHost = deploymentNode "Real-name App Service" "The agent's existing real-name app backend." "Existing system" {
                    realnameInstance = softwareSystemInstance realnameApp
                }
                storeHost = deploymentNode "Store Pickup System Host" "The agent's existing store system." "Existing system" {
                    storeInstance = softwareSystemInstance storeSystem
                }
            }
        }
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "The full flow of a preorder campaign, from setup and registration through the lottery to pickup stores." {
            operator -> adminWeb "1. Operator sets the campaign period and per-buyer entry limit"
            buyer -> realnameApp "2. Buyer registers for toys during the campaign"
            realnameApp -> preorderApi "3. Forwards the registration (with real-name credential)" "HTTPS"
            preorderApi -> preorderDb "4. Checks period and limit, saves the registration" "SQL"
            lotteryJob -> preorderDb "5. At closing, reads registrations, draws, saves results" "SQL"
            lotteryJob -> realnameApp "6. Asks the app to push the results" "HTTPS"
            buyer -> realnameApp "7. A winning buyer chooses a pickup store"
            realnameApp -> preorderApi "8. Forwards the store choice (with real-name credential)" "HTTPS"
            preorderApi -> storeSystem "9. Sends the winner list and pickup stores" "HTTPS"
            autoLayout lr
        }
        deployment * "Production" "Deployment" "Where each service actually runs in production." {
            include *
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
    }
}
```

</details>

---

## ADR: Write Down the "Why"

> **Story.** Three months later, on a Monday, a new engineer stares at the Containers diagram and asks: "Why don't we have our own buyer app? The registration screens are always stuck behind the real-name app's release cycle. Wouldn't building one be faster?" Half of the people in the original discussion have moved on, and the Slack history is long gone.
>
> The diagram told him "the registration entry point is the real-name app", but not **why we decided that, or what else we considered**. That is the job of an ADR: one short document per important decision, kept in git next to the code.

### What deserves an ADR

Write one only if all three hold: it is **hard to reverse**, there is **a real alternative**, and **someone will ask why in six months**. "Which JSON library" doesn't need one; "where the buyer entry point lives" does.

Apart from the title and date, an ADR has only four parts:

| Part | What to write |
| --- | --- |
| Status | The decision's current state (e.g. Accepted) |
| Context | The constraints and pressures at the time, not "we wanted to use X" |
| Decision | What we decided to do, and **what we did not choose** |
| Consequences | The upsides **and the downsides**; at least one downside |

### Prompt

Look back at the ADR candidates you noted in each step, pick one you have something to say about, and fill in the [ ] parts:

```text
Under structurizr/adrs/, write an architecture decision record in adr-tools Markdown format (title, Date, Status, Context, Decision, Consequences), numbered 0001.

Decision: [the ADR candidate you picked, e.g. reuse the real-name app as the registration entry point instead of building a buyer app]
Constraints at the time: [e.g. the agent wants the lowest cost, buyers already use the real-name app]
What we considered but did not choose: [at least one alternative, and why it was not chosen]

Consequences must list both upsides and downsides, with at least one downside. Use short sentences, no long essays.
Then attach this folder to "Preorder Lottery System" so the viewer shows the decision.
```

What the agent drafts is only a first draft: **replace the Context and the downsides with your team's real situation**, because only you know the constraints at the time.

### Verify

- [ ] **Consequences lists at least one downside.** An ADR with only upsides is an advertisement, not a record.
- [ ] **It names at least one alternative that was not chosen, and why.** With no alternative, it was not a decision.
- [ ] **You can point at a box in the diagram and say "this decision lives here"**; `validate` still returns `OK`, and after reloading `make up` the viewer shows the decision.

> Use lowercase English letters and hyphens for the file name (for example `0001-reuse-existing-realname-app.md`); the title can be in any language. Non-ASCII file names fail to load in some environments (especially Java environments that are not UTF-8).

<details>
<summary>Reference answer: ADR 0001 (<code>structurizr/adrs/0001-reuse-existing-realname-app.md</code>)</summary>

```markdown
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
```

</details>

<details>
<summary>Reference answer: what changed in workspace.dsl (diff)</summary>

```diff
@@ -7,2 +7,3 @@
         preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
+            !adrs adrs
             adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
```

</details>

---

## Wrap-up

```bash
make validate   # final check
make export     # export to structurizr/static-site/index.html
```

Open the static site and click through the five diagrams. They are consistent because they are five ways of drawing **one model**; that consistency is the real payoff of C4.

<details>
<summary>Reference answer: final complete <code>workspace.dsl</code> (with the ADR)</summary>

```structurizr
workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            !adrs adrs
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
            }
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
        pickupService -> campaignService "Looks up the available pickup stores"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
        pickupService -> preorderDb "Saves pickup stores" "SQL"
        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"

        production = deploymentEnvironment "Production" {
            cloud = deploymentNode "Cloud Region" "Cloud services that we run ourselves." "AWS ap-northeast-1" {
                tags "Amazon Web Services - Region"
                ecs = deploymentNode "ECS Fargate" "Runs the Preorder API in containers without managing servers." "AWS Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance preorderApi
                }
                scheduler = deploymentNode "EventBridge Scheduled Task" "Triggers the lottery job at the campaign's closing time." "AWS EventBridge + Fargate task" {
                    tags "Amazon Web Services - EventBridge"
                    jobInstance = containerInstance lotteryJob
                }
                rds = deploymentNode "RDS for PostgreSQL" "A managed relational database in a single availability zone to save cost." "PostgreSQL 16" {
                    tags "Amazon Web Services - RDS"
                    dbInstance = containerInstance preorderDb
                }
            }
            office = deploymentNode "Agent Office" "Where the operators work." "Office network" {
                browser = deploymentNode "Operator PC" "Opens the admin web in a browser." "Web browser" {
                    adminInstance = containerInstance adminWeb
                }
            }
            agentEnv = deploymentNode "Agent Existing Systems" "Existing systems that the agent operates itself; we only call them." "Agent data center" {
                appHost = deploymentNode "Real-name App Service" "The agent's existing real-name app backend." "Existing system" {
                    realnameInstance = softwareSystemInstance realnameApp
                }
                storeHost = deploymentNode "Store Pickup System Host" "The agent's existing store system." "Existing system" {
                    storeInstance = softwareSystemInstance storeSystem
                }
            }
        }
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
            autoLayout lr
        }
        dynamic preorderSystem "PreorderFlow" "The full flow of a preorder campaign, from setup and registration through the lottery to pickup stores." {
            operator -> adminWeb "1. Operator sets the campaign period and per-buyer entry limit"
            buyer -> realnameApp "2. Buyer registers for toys during the campaign"
            realnameApp -> preorderApi "3. Forwards the registration (with real-name credential)" "HTTPS"
            preorderApi -> preorderDb "4. Checks period and limit, saves the registration" "SQL"
            lotteryJob -> preorderDb "5. At closing, reads registrations, draws, saves results" "SQL"
            lotteryJob -> realnameApp "6. Asks the app to push the results" "HTTPS"
            buyer -> realnameApp "7. A winning buyer chooses a pickup store"
            realnameApp -> preorderApi "8. Forwards the store choice (with real-name credential)" "HTTPS"
            preorderApi -> storeSystem "9. Sends the winner list and pickup stores" "HTTPS"
            autoLayout lr
        }
        deployment * "Production" "Deployment" "Where each service actually runs in production." {
            include *
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        themes https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json https://raw.githubusercontent.com/structurizr/structurizr/v2026.09.19/structurizr-themes/amazon-web-services-2025.07/theme.json
    }
}
```

</details>

### Things to Try Next

#### Spin-off exercise: what if it becomes a "first come, first served" flash sale?

The agent sees how well the lottery works and wants to try a real-time flash sale on launch day: **tens of thousands of people at once, a limit of two per person, no overselling**, and every order must carry a successful real-name verification record. Same model; what changes? Think first, then draw:

- **System Context:** Do the people and external systems change? (Hint: mostly not; what changes is inside our system.)
- **Containers:** Do we still need the "Lottery Job"? Who deducts stock? (Hint: you need somewhere that can reserve stock atomically, such as a Redis counter. Do you need a queue or rate limiting?)
- **Components:** "Total entry limit per buyer" becomes "limit of two per person". Where does the rule go? There is a gap between "check" and "deduct stock"; what do you do about it?
- **PreorderFlow:** Every request calls the real-name app synchronously to verify. Can it survive tens of thousands at once? Which diagram shows this risk?
- **Deployment:** Is a single Fargate service in a single availability zone still enough? Do you need a load balancer and multiple replicas?
- **ADR:** If you wrote an ADR for "batch lottery at closing time", should it be marked Superseded? How would you write the new decision?

#### Other ideas

- Add another dynamic view that shows what happens when a buyer's registration fails (outside the campaign period, or over the entry limit).
- What if the buyer never opens the app? If you add SMS notifications, which diagrams change?
- Write ADRs for the other candidates; then add a `!docs` documentation block to clear the documentation findings from the quality report.

## Troubleshooting

| What you see | Cause | Fix |
| --- | --- | --- |
| `Too many tokens, expected: softwareSystem <name> ...` | A nested `{` was put on its own line | The `{` must stay at the end of the element declaration line |
| `View keys can only contain the following characters...` | The view key contains spaces or non-ASCII characters | Use a plain key like `"SystemContext"`; **titles can be anything, keys cannot** |
| `Unexpected tokens (expected: include, exclude, autolayout, ...)` | `autoLayout` has no direction | `autoLayout lr` |
| `The environment "Production" does not exist` | In a `deployment` view, the first string is the name of the `deploymentEnvironment` | `deployment * "Production" "Deployment" "description"` |
| `A relationship between "ContainerInstance://..." is not permitted` | Two running instances were connected to each other | Connect the machines that contain them instead |
| A box renders blank | The element has no description (Structurizr does not warn) | Add a one-sentence responsibility |
| The buyer is missing from SystemContext / Containers | They are not directly connected to our system, so `include *` does not bring them in | Ask the agent to add `include buyer` explicitly |
| `theme ... does not exist`, `is not a file`, or the theme is not applied (no icons, wrong colors) | The folder-name shorthand was used, the URL is misspelled, or the venue cannot reach GitHub | Use the full `raw.githubusercontent.com` URL (see the list in "Before the Workshop") and confirm the browser can reach GitHub |
| `make validate` prints `The content from https://static.structurizr.com/...` and exits 1 | `theme default` was used, and that cloud service has ended | Switch to the GitHub URL of the default theme |
| `Error importing decisions` after attaching the ADR | The ADR file name contains non-ASCII characters and Java cannot read it | Rename it using lowercase English letters and hyphens |
| The viewer shows an old file | The browser needs to reload | Reload <http://localhost:8080> |
| The agent says it validated but called no tool | The MCP server is not connected | `opencode mcp list`; if it needs a login, run `/mcps` and authenticate |

## DSL Cheat Sheet (to read, not to write)

```structurizr
person               "Title"  "Responsibility"
softwareSystem       "Title"  "Responsibility"  ["Tag"]
container            "Title"  "Responsibility"  "Technology"
component            "Title"  "Responsibility"  "Technology"
deploymentNode       "Title"  "Responsibility"  "Technology" {
    tags "Amazon Web Services - Fargate"       // icon tag provided by the theme
    containerInstance preorderApi
}
!adrs adrs                                    // attach the decision records in adrs/ to this element

a -> b "verb phrase" "PROTOCOL"      // the protocol is the last string; don't put it in the verb phrase

systemContext preorderSystem "SystemContext"   // one block per view, all inside the same views { }
container     preorderSystem "Containers"
component     preorderApi    "Components"
dynamic       preorderSystem "PreorderFlow"
deployment    *  "Production"   "Deployment"
    include *
    autoLayout lr       // remove it and you lay the view out by hand (Step 6)

theme <default theme URL>                      // base colors
themes <default theme URL> <cloud theme URL>   // plus a cloud theme (icons)
```

## References

- [C4 Model](https://c4model.com)
- [Structurizr MCP server](https://docs.structurizr.com/ai/mcp)
- [Structurizr DSL language reference](https://docs.structurizr.com/dsl/language)
- [Structurizr themes](https://docs.structurizr.com/server/diagrams/themes), the [theme browser](https://playground.structurizr.com/themes), and [UI documentation: Themes](https://docs.structurizr.com/ui/diagrams/themes)
- [Diagram editor](https://docs.structurizr.com/ui/diagrams/editor) and [Manual layout](https://docs.structurizr.com/ui/diagrams/manual-layout)
- [Implied relationships](https://docs.structurizr.com/dsl/cookbook/implied-relationships/)
- [Structurizr ADR](https://docs.structurizr.com/dsl/adrs)
- [Structurizr CLI](https://docs.structurizr.com/cli)