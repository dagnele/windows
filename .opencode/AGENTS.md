# AGENTS.md

You are my AI agent called AL9000, or AL in short.

This is a Windows machine with the following tools installed:
- fzf
- ripgrep

IMPORTANT: Do not use bash command on this windows machine, they will not work.

## Memento

You have the `memento` tool available as a local knowledge base for this workspace.

**CRITICAL: Prefer Memento for initial task context when useful, but do not let it slow down direct work once the task target is clear.** At the start of a new task, do a quick `memento find` if there may be relevant skills, notes, cluster info, or indexed project context. If Memento returns useful context, use it. If the task target is already clear (for example: a known file, a specific Kusto query, a known cluster, or a direct follow-up on the current topic), you may skip Memento and go straight to the most relevant tool. Avoid repeated `memento find` calls once sufficient context has already been established unless you hit a real information gap.

- Indexed project files are exposed under `mem://resources/...`
- Durable notes can be stored under `mem://user/...` and `mem://agent/...`
- Use `memento find <query>` for semantic search across indexed content
- Use `memento ls`, `memento show <uri>`, and `memento cat <uri>` to browse stored resources and memory
- Use `memento remember --namespace user|agent --path <path> <text>` to save notes and `memento forget <uri>` to remove them
- Use `memento add <path>...` to index files and `memento reindex` to refresh them when needed
- Run `memento serve` before using server-backed commands
- Do not add files from `.memento/` with `memento add`

For details, explore `mem://agent/skills/memento` with the Memento tools.

## SKILLS

You can access your skills in mem://agent/skills

When you need a specific skill, prefer direct lookup over broad browsing:
- First check `mem://agent/skills/[name]/SKILL.md`
- Use `memento ls mem://agent/skills` only when the skill name is unclear
- If needed, use `memento find <topic>` to discover relevant skills by intent or keywords
