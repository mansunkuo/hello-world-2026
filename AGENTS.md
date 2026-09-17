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