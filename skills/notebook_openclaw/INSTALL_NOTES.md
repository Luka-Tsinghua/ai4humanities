# Install Notes (ZH/EN)

## ZH
- macOS/Linux（桌面）：可直接在本机运行 `notebooklm login` 完成登录。
- Windows：在 PowerShell 中运行 `notebooklm login`。
- WSL2 / headless：在宿主机/带 GUI 的机器完成登录后，把 `NOTEBOOKLM_HOME/storage_state.json` 安全复用到目标环境（WSL2 推荐软链接到 `/mnt/c/.../.notebooklm/storage_state.json`）。

## EN
- macOS/Linux (desktop): run `notebooklm login` locally.
- Windows: run `notebooklm login` in PowerShell.
- WSL2 / headless: login on a GUI machine, then securely reuse `NOTEBOOKLM_HOME/storage_state.json` in the target environment (WSL2: symlink from `/mnt/c/.../.notebooklm/storage_state.json`).
