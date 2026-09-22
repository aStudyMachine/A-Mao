# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root, or
- **`CONTEXT-MAP.md`** at the repo root if it exists: it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. In multi-context repos, also check `<context>/docs/adr/` for context-scoped decisions.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. Domain modeling creates them lazily when terms or decisions actually get resolved.

## File structure

Single-context repo (most repos):

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0000-adr写作模板.md
│   └── 0001-xxx.md
└── src/
```

Multi-context repo (presence of `CONTEXT-MAP.md` at the root):

```
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← system-wide decisions
└── <context-a>/
│   ├── CONTEXT.md
│   └── docs/adr/                      ← context-specific decisions
└── <context-b>/
    ├── CONTEXT.md
    └── docs/adr/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids (the `_Avoid_` lines exist for this).

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for domain modeling / knowledge distill).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (xxx), but worth reopening because…_
