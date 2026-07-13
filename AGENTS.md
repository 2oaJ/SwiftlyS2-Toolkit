# SwiftlyS2 Toolkit Codex Instructions

## Canonical entry

- Read `skills/swiftlys2-toolkit/SKILL.md` completely before planning, editing, or reviewing SwiftlyS2 work.
- In a downstream project, also read the nearest applicable `AGENTS.md` and any project-local skills it names.
- Route direct implementation, planning, and auditing through `skills/swiftlys2-toolkit/references/edit-workflow.md`, `skills/swiftlys2-toolkit/references/plan-workflow.md`, and `skills/swiftlys2-toolkit/references/audit-workflow.md` respectively.

## Codex-native layout

- `skills/swiftlys2-toolkit/` is the canonical reusable skill. Keep reusable domain guidance, references, scripts, and assets inside it.
- `.codex/agents/*.toml` contains Codex subagent roles. Keep each role narrow, independently verifiable, and explicit about read/write scope.
- `skills/swiftlys2-toolkit/agents/openai.yaml` is UI metadata for the skill, not a substitute for subagent role definitions.
- Do not add IDE-vendor-specific agent, prompt, instruction-file, handoff-button, tool-list, or Chat Mode compatibility paths.

## Implementation rules

- Prefer the smallest correct change and preserve the target project's current architecture.
- Do not add backward-compatibility branches, aliases, adapters, fallback routes, or duplicate read/write paths unless the current user request explicitly requires them.
- Treat map load/unload, player connect/disconnect, main-thread-sensitive APIs, delayed `IPlayer` access, bot identity, entity handles, and worker cancellation as mandatory review boundaries when relevant.
- For high-frequency hooks, prove the hotspot before adding pooling, `Span`, `stackalloc`, aggressive inlining, or native interop optimizations.
- Do not claim completion from static reading or a successful build alone. Drive the changed behavior through its matching runtime surface when one exists.

## Public references

Public toolkit material may depend only on SwiftlyS2 official documentation, the SwiftlyS2 official repository, and `sw2-mdwiki`. Keep private paths, project names, credentials, and workspace-only rules in the downstream project's `AGENTS.md` or a project-local skill.

## Validation

Before committing toolkit changes:

1. Validate `skills/swiftlys2-toolkit` with the installed `skill-creator` validator.
2. Parse `.codex/config.toml` and every `.codex/agents/*.toml` with a TOML parser.
3. Scan the tracked tree for legacy IDE-specific agent/prompt formats and broken paths.
4. Re-read the full diff and keep generated metadata synchronized with `SKILL.md`.
