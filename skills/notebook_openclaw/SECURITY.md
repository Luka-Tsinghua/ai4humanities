# Security Policy

## Do not commit secrets

NotebookLM authentication artifacts (e.g. `storage_state.json`, browser profile directories) contain session cookies and should be treated like passwords.

- Never commit these files to git.
- Never paste them into GitHub issues, chats, logs, or screenshots.
- If you suspect leakage, re-run `notebooklm login` to rotate the session.

This skill includes `gitignore.snippet` to help you block sensitive files.

## Safe-by-default expectations

- All documentation in this folder avoids personal identifiers.
- All paths are written with placeholders (e.g., `<YOUR_WINDOWS_USER>`).
- Scripts write logs/reports under the skill directory, not to user-specific locations.
