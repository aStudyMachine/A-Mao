# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

> 定位：本仓库唯一的 issue 跟踪器——本地 markdown，不入外部系统。适合单人/小团队 + AI Agent 协作的节奏：spec 与 issue 都是可被 Agent 直接读写的文件，随特性一起归档。

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by multi-step research/efforts. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.

## 方案/计划文档存放约定

TRAE 产出的方案文档统一存于项目根 `.trae/documents/`（本地目录，不入库）；其他 Agent 产出的方案文档统一存于项目根 `.agents/plan/`（命名 `<slug>-plan.md`，随方案推进可迭代覆盖）；**已批准进入实施**的方案归档到 `.scratch/<feature-slug>/` 与 spec/issue 同目录，验收随特性清场。禁止散落在仓库根、`docs/` 等正式目录。

## 清场约定

发布收尾（release 技能）时：已完成特性的目录归档或清理，`.scratch/` 只留进行中的特性。
