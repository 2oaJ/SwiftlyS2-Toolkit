# SwiftlyS2-Toolkit

A Codex-first toolkit for planning, implementing, auditing, and reviewing **SwiftlyS2 C#/.NET plugins**.

The reusable domain workflow lives in one self-contained skill. Optional Codex subagent roles provide narrow research, planning, implementation, and review scopes without duplicating the skill's rules.

## Repository layout

```text
AGENTS.md                              Codex repository guidance
.codex/
  config.toml                         Project-local subagent registration
  agents/
    swiftlys2-researcher.toml         Read-only investigation
    swiftlys2-planner.toml            Read-only method-level planning
    swiftlys2-implementer.toml        Bounded implementation and verification
    swiftlys2-reviewer.toml           Read-only findings-first review
skills/swiftlys2-toolkit/
  SKILL.md                            Canonical skill entry
  agents/openai.yaml                  Codex skill UI metadata
  references/                         Workflow and domain references
  assets/                             Templates, checklists, and guides
```

Legacy IDE-vendor agent, prompt, handoff, and tool-list formats are intentionally not shipped. Codex uses `AGENTS.md` for durable repository rules, `SKILL.md` for reusable workflow knowledge, `agents/openai.yaml` for skill metadata, and `.codex/agents/*.toml` for specialized subagent roles.

## Install for Codex

### 1. Install the skill

Copy `skills/swiftlys2-toolkit` into `${CODEX_HOME}/skills/`. When `CODEX_HOME` is unset, use `~/.codex`.

PowerShell:

```powershell
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$SkillTarget = Join-Path $CodexHome 'skills\swiftlys2-toolkit'
New-Item -ItemType Directory -Force $SkillTarget | Out-Null
Copy-Item -Recurse -Force '.\skills\swiftlys2-toolkit\*' $SkillTarget
```

Git Bash / POSIX shell:

```bash
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME/skills"
cp -R skills/swiftlys2-toolkit "$CODEX_HOME/skills/"
```

### 2. Install the optional subagent roles

Copy `.codex/agents/*.toml` into `${CODEX_HOME}/agents/`, then merge the four `[agents.*]` sections from `.codex/config.toml` into `${CODEX_HOME}/config.toml`. Do not replace an existing global config wholesale.

The checked-out repository already contains the same registration as project-local Codex configuration.

## Use

Invoke the skill directly when you want the main Codex agent to own the complete task:

```text
Use $swiftlys2-toolkit to audit this plugin's RuntimeLoop and fix the confirmed lifecycle issues.
```

The skill routes work to three canonical workflow references:

- `skills/swiftlys2-toolkit/references/edit-workflow.md` for direct implementation
- `skills/swiftlys2-toolkit/references/plan-workflow.md` for method-level planning
- `skills/swiftlys2-toolkit/references/audit-workflow.md` for systematic review and risk discovery

Use subagents only when the work splits into independent, verifiable scopes. The parent Codex agent remains responsible for final decisions, integration, high-risk changes, and acceptance.

## Public reference sources

Toolkit guidance is grounded in:

1. [SwiftlyS2 official documentation](https://swiftlys2.net/docs/)
2. [sw2-mdwiki](https://github.com/himenekocn/sw2-mdwiki)
3. [SwiftlyS2 official repository](https://github.com/swiftly-solution/swiftlys2)

Keep workspace-specific paths, private repositories, credentials, and project rules in the downstream repository's `AGENTS.md` or project-local skills. Do not write them back into this public toolkit.

## License

MIT
