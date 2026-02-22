# NotebookLM × OpenClaw（Docs-first）— `notebook_openclaw`

[English](README.md) · [中文](README_ZH.md)

<p align="center">
  <b>拒绝盲改 OpenClaw 配置。</b><br/>
  用 NotebookLM 搭一个可检索的官方文档知识库，让 Agent 先查文档再动手。
</p>

<p align="center">
  <a href="https://github.com/teng-lin/notebooklm-py"><img alt="notebooklm-py" src="https://img.shields.io/badge/notebooklm--py-%E7%A4%BE%E5%8C%BA%E9%A1%B9%E7%9B%AE-blue"></a>
  <a href="https://docs.openclaw.ai/"><img alt="OpenClaw Docs" src="https://img.shields.io/badge/OpenClaw-%E5%AE%98%E6%96%B9%E6%96%87%E6%A1%A3-green"></a>
  <img alt="English-only" src="https://img.shields.io/badge/sources-%E5%8F%AA%E4%BF%9D%E7%95%99%E8%8B%B1%E6%96%87-success">
  <img alt="Security" src="https://img.shields.io/badge/security-%E4%B8%8D%E6%8A%8A%E7%A7%98%E9%92%A5%E6%94%BE%E8%BF%9B%20git-critical">
</p>

---

## 为什么需要它

在日常使用 OpenClaw 时，你可能遇到过：

- 想配置 heartbeat，却不确定正确配置路径
- 想给 gateway 添加新 channel，却不知道该用哪个命令参数
- 想确认某个新功能的默认值，却无从下手

直接把要求发给大模型，经常一不小心就改错参数，搞崩了 OpenClaw，你还得手动修复。❌

OpenClaw 反复强调：它不做过度“傻瓜式”封装，是为了让用户理解每一项配置的含义。官方 GitHub 的 `VISION.md` 中有明确表述：

> Long term, we want easier onboarding flows as hardening matures.  
> We do not want convenience wrappers that hide critical security decisions from users.  
> （长期来看，随着安全加固成熟，我们会提供更简单的上手流程；但我们不想要那些向用户隐藏关键安全决策的便捷封装。）

**AI Agent 不是傻瓜许愿机！** 🤖  
想让它老老实实干活儿，除了约束文档外，一个可供 Agent 快速检索的 **OpenClaw 官方文档知识库**，绝对是利器。

Google NotebookLM 很适合做这件事；而 `notebooklm-py`（社区项目）提供了 Python CLI，让我们能把 **“导入文档 → 可检索问答”** 自动化起来。

---

## 这个 skill 做什么

- 在 NotebookLM 中创建/使用一个笔记本（建议命名：`OpenClaw_Doc`）
- 从 `docs.openclaw.ai` 的 sitemap 批量导入文档
- **只保留英文页面（English-only）**：排除非英文路由（例如 `/zh-CN`）
- 提供增量同步脚本：`tools/sync_openclaw_doc.sh`
- 可选：用 OpenClaw cron 定时自动同步
- 固化纪律：**先查文档 → 再写配置**

---

## ⚠️ 安全提醒（必读）

NotebookLM 的认证状态保存在 `storage_state.json`（以及可能的浏览器 profile 目录）里，它等同“会话钥匙/密码”。

- **不要提交到 Git**
- **不要粘贴到 issue/聊天**
- **不要公开分享**

本目录提供 `gitignore.snippet`，用于屏蔽敏感文件。

---

## 🛠️ 1) 安装与认证

项目地址： https://github.com/teng-lin/notebooklm-py

安装：

```bash
pip install -U notebooklm-py
```

首次登录建议安装浏览器依赖：

```bash
pip install -U "notebooklm-py[browser]"
playwright install chromium
```

登录（需要浏览器）：

```bash
notebooklm login
```

💡 建议策略：使用 `NOTEBOOKLM_HOME` 统一认证目录，便于迁移：

Linux/macOS:

```bash
export NOTEBOOKLM_HOME="$HOME/.notebooklm"
```

PowerShell:

```powershell
$env:NOTEBOOKLM_HOME = "$env:USERPROFILE\.notebooklm"
```

---

## 🔗 2) WSL2 跨系统认证（仅 Windows + WSL2 需要）

本文默认环境：OpenClaw 安装在 WSL2 Ubuntu。WSL2 往往是 headless（无 GUI），无法直接完成 `notebooklm login` 的浏览器交互。

解决方案：**Windows 宿主机登录 → WSL2 软链接复用认证**。

宿主机登录（Windows PowerShell）：

```powershell
notebooklm login
```

WSL2 建目录 + 建软链接 + 验证：

```bash
mkdir -p ~/.notebooklm
ln -sf /mnt/c/Users/<YOUR_WINDOWS_USER>/.notebooklm/storage_state.json ~/.notebooklm/storage_state.json
notebooklm auth check --test --json
```

认证过期时：只需在 Windows 端重新 `notebooklm login`，WSL2 会通过软链接自动生效。

---

## 📚 3) 创建笔记本并导入文档（English-only）

创建并设置默认上下文：

```bash
notebooklm create "OpenClaw_Doc"
echo '{"notebook_id":"<NOTEBOOK_ID>"}' > ~/.notebooklm/context.json
```

批量导入（只保留英文页面）：

```bash
bash tools/sync_openclaw_doc.sh
```

脚本会解析 sitemap、去重 URL、排除非英文路由，并生成同步报告。

---

## ⏰ 4) 定时自动同步（更运维友好）

OpenClaw 文档会持续更新。建议用 OpenClaw 的 cron 机制做 **增量对齐（incremental sync）**：

- 可重复执行（idempotent）
- 只做必要变更（增量补齐 + 记录失败）
- 输出报告（added / failed）
- 适当限速（避免触发限流）

创建任务：

```bash
openclaw cron add --name "notebook_openclaw" \
  --cron "0 5 * * 2" --tz "<YOUR_TIMEZONE>" \
  --description "Incrementally sync OpenClaw_Doc sources (English-only) from docs.openclaw.ai sitemap" \
  --message "bash {baseDir}/tools/sync_openclaw_doc.sh" --announce
```

手动触发一次验证：

```bash
openclaw cron run --name "notebook_openclaw"
```

---

## 🔍 5) 使用场景与查询方法

必须先查文档的场景纪律：

- 配置变更前：确认正确字段路径
- 参数不确定：确认 JSON path / CLI 行为
- 新功能调研：默认值与推荐用法
- 问题排查：检索异常关键字对应章节

查询命令：

```bash
notebooklm ask "How to set heartbeat target to feishu" --json
```

Markdown 格式回答：

```bash
notebooklm ask "Explain heartbeat configuration and defaults" --format markdown
```

---

## ✅ 实际应用案例：每小时 heartbeat + 显式显示 `heartbeat_OK`

关键点：**`heartbeat_OK` 默认不一定展示**（为减少噪音）。如果你希望“正常/健康”的心跳也能被人看见，需要显式开启 “show OK” 行为。

✅ 正确流程：

1) Agent 先在 `OpenClaw_Doc` 里查文档：确认 `showOk`（或等价字段）的准确路径与默认值  
2) 再写入配置（不是凭经验盲填）  

示例（Feishu 渠道）：

```bash
openclaw config set agents.defaults.heartbeat.every "1h"
openclaw config set agents.defaults.heartbeat.target "feishu"

# 关键：显式展示 heartbeat_OK（默认通常为 false）
openclaw config set channels.feishu.heartbeat.showOk true
```

---

## 🏁 总结

`notebook_openclaw` 的核心不是“更方便”，而是把 **“改配置前先查文档”** 固化为流程纪律：

- WSL2 认证复用：解决无头环境登录难题
- 增量同步：长期对齐官方文档（English-only）
- 检索先行：拒绝盲目 patch，守护系统稳定与安全 💪
