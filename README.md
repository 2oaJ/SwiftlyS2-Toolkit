# SwiftlyS2-Toolkit

A standard-format agent skill for planning, implementing, auditing, and reviewing **SwiftlyS2 C#/.NET plugins**.

The repository root is the skill root: `SKILL.md` is the canonical entry, and all workflow references, templates, and checklists live directly beside it. No vendor-specific adaptation layer is shipped — any coding agent that reads standard `SKILL.md` skills can use it as-is.

## Repository layout

```text
SKILL.md                 Canonical skill entry (frontmatter: name, description)
references/              Workflow and domain references
assets/                  Templates, checklists, and guides
AGENTS.md                Repository guidance for coding agents
LICENSE                  MIT
```

## Install

### As a git submodule (recommended for downstream repositories)

```bash
git submodule add https://github.com/2oaJ/SwiftlyS2-Toolkit.git .agents/skills/swiftlys2-toolkit
git submodule update --init --recursive
```

### As a plain copy

Copy this repository into the skills directory of your agent tool so that `SKILL.md` sits directly under the skill folder, for example:

```bash
cp -R SwiftlyS2-Toolkit /path/to/skills/swiftlys2-toolkit
```

## Use

Invoke the skill by its name `swiftlys2-toolkit` whenever working on SwiftlyS2 plugin code:

```text
Use swiftlys2-toolkit to audit this plugin's RuntimeLoop and fix the confirmed lifecycle issues.
```

The skill routes work to three canonical workflow references:

- `references/edit-workflow.md` for direct implementation
- `references/plan-workflow.md` for method-level planning
- `references/audit-workflow.md` for systematic review and risk discovery

## Public reference sources

Toolkit guidance is grounded in:

1. [SwiftlyS2 official documentation](https://swiftlys2.net/docs/)
2. [sw2-mdwiki](https://github.com/himenekocn/sw2-mdwiki)
3. [SwiftlyS2 official repository](https://github.com/swiftly-solution/swiftlys2)

Keep workspace-specific paths, private repositories, credentials, and project rules in the downstream repository's `AGENTS.md` or project-local skills. Do not write them back into this public toolkit.

## License

MIT
