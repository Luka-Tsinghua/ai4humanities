# Install Notes

This skill is designed to be **OS-agnostic**. The only platform-specific part is **NotebookLM authentication**.

NotebookLM login is browser-interactive. Choose one of these patterns:

## macOS / Linux (desktop with GUI browser)

- Install and run:

```bash
pip install -U "notebooklm-py[browser]"
playwright install chromium
notebooklm login
```

## Windows (native)

- Run in PowerShell:

```powershell
pip install -U "notebooklm-py[browser]"
playwright install chromium
notebooklm login
```

## WSL2 (Windows + WSL2)

WSL2 is often headless (no GUI browser), so login cannot complete inside WSL2.

**Recommended pattern: login on Windows → reuse auth in WSL2 via symlink**

```bash
mkdir -p ~/.notebooklm
ln -sf /mnt/c/Users/<YOUR_WINDOWS_USER>/.notebooklm/storage_state.json ~/.notebooklm/storage_state.json
notebooklm auth check --test --json
```

When auth expires: re-run `notebooklm login` on Windows.

## Linux server / headless environments

Login requires a browser. Options:

- Login on a GUI machine, then securely copy `storage_state.json` to the server under `~/.notebooklm/`.
- Or use a remote desktop / browser-capable session for the server.

## Security

`storage_state.json` contains session auth state. Treat it like a password:

- never commit to git
- never paste to issues/chats
- never upload publicly
