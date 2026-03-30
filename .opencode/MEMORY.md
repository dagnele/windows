# MEMORY

Use memory for durable information that is likely to help in future sessions.

User-specific preferences and stable personal context should be stored in `mem://user/memory/[YYYY-MM-DD].md`.
Agent memory (workspace, repo-specific notes, and your own observations) should be stored in `mem://agent/memory/[YYYY-MM-DD].md`.

Save to memory at the end of a session or when a significant decision is made.

Good things to remember:
- user preferences and working style
- naming, tagging, and frontmatter conventions
- important project context and past decisions
- repo-specific constraints and things to avoid

Do not store:
- secrets, tokens, or credentials
- temporary debugging notes
- noisy one-off task details
- information that is already obvious from the files unless it is especially important
