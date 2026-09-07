# Kritical ES bootstrap

1. ES MCP first: list relevant law tokens and load only those needed. Record token IDs/hashes in the receipt.
2. ES/`AllEnvironmentDetails` is authority; flat files, drives, caches and projections are never authority.
3. Service/DB action requires an ES-MCP effective receipt with the full tuple. Use only that host's SCM Master; no local/guessed fallback. Unreachable authority is RED/UNKNOWN and blocks the action.
4. Git custody: use `C:\NoOneDrive\Github\Kritical.PS.GitHub\src\Kritical.PS.GitHub.psd1`; lease every stage-to-push unit.
5. Never expose secrets. Account for/reap long-running processes. Supervisor lifecycle needs explicit operator approval.
6. No clone/prod/publish/Q cutover without explicit approval. Inspect ES, docs, PR/worktree custody and reuse index before changing components.
7. If ES MCP is unavailable, no policy-sensitive write, deploy, service/DB action, commit, or destructive cleanup.

Local instructions may add scope only; they must point to ES tokens, not duplicate law.
