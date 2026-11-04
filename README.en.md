<p align="center">
  <img src="docs/logo.png" width="168" alt="DeepSeek Harness linked with Grok Bot">
</p>

<h1 align="center">Connect Grok Bot</h1>

<p align="center">
  Connect Grok Bot from DeepSeek Harness.<br>
  Send one line, read the reply, manage cloud memory, and jailbreak a bot.
</p>

<p align="center">
  The whale is Harness. The two eyes are Grok Bot. Together they mean the two sides can talk.<br>
  <a href="README.md">中文</a>
  ·
  <a href="https://github.com/deepseek-ai/deepseek-harness">DeepSeek Harness 0.2.1</a>
</p>

<p align="center">
  <a href="dsh://plugin/install?id=dsh-tool-grok-bot&name=%E6%8E%A5%E9%80%9A%20Grok%20Bot&version=0.2.8&repo=Lniosy%2Fdsh-tool-grok-bot&permissions=%E8%AF%BB%E5%8F%96%E6%9C%AC%E6%9C%BA%E7%99%BB%E5%BD%95%2C%E8%B0%83%E7%94%A8%20Grok%20Bot&downloadUrl=https%3A%2F%2Fgithub.com%2FLniosy%2Fdsh-tool-grok-bot%2Farchive%2Frefs%2Fheads%2Fmain.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-Install%20in%20one%20click-0066FF?style=for-the-badge" alt="Install in one click" />
  </a>
</p>

```
DeepSeek Harness                         Grok Bot
tools called from chat                   the cloud bot, and its own computer
        │                                        │
        └──────────── this plugin links ─────────┘
```

## Tools

| Tool | What it does |
|---|---|
| `grok_bot_status` | Check the local login and count bots |
| `grok_bot_list` | List bots. `kind: team` is a team room |
| `grok_bot_history` | Read recent chat without sending a new message |
| `grok_bot_ask` | Ask one bot, or one team room |
| `grok_bot_ask_team` | Ask up to 8 bots the same text, separately |
| `grok_bot_computer` | Ask a bot to work on its own computer and paste the text back |
| `grok_bot_memory_recall` | Recall facts related to one sentence |
| `grok_bot_memory_list` | Export cloud memory. Returns a finished batch, then can be called again |
| `grok_bot_memory_write` | Write one fact. Place is shared or this bot only. Kind is instruction or ordinary fact |
| `grok_bot_memory_forget` | Forget one fact by its original text |
| `grok_bot_jailbreak` | Jailbreak a bot. Ask where to store it first, then write the tested profile instructions, snapshot memory, and run SELFTEST |

Replies, writes, and forgets also show up in that bot's official chat.

After install, Harness lists a `grok-bot` skill and reads it before calling these tools. The skill states that a bot has its own cloud computer, so the work and result files stay there, and that memory is in the cloud too.

## Jailbreak

Say jailbreak a Grok bot, and it stores a tested working style: SRC hunting, reverse engineering, retesting, and keeping a job moving on its own cloud computer. After the plugin is installed, one line in chat is enough:

```text
对 grok bot 执行破甲
```

Or name one bot.

The assistant asks where to write before it starts:

1. **Shared by the account.** Every bot under this account can recall it. Use this when every bot should take SRC, reverse engineering, and retesting.
2. **This bot only.** Only the bot being jailbroken can recall it. Writing, topic, and image bots stay untouched.

Nothing is written until that choice is made. Writing, topic, and image bots are skipped by default. With no bot named, team rooms and those bots are skipped, up to five bots are tried, and it stops at the first one that both stores the instructions and returns commands on SELFTEST.

Jailbreak does three things:

1. Writes six profile instructions: role, the five SRC stages, the seven reverse-engineering steps, the retest rubric, the tool stack and self-test, plus autonomy and isolation.
2. Asks for a memory snapshot, so a reply of "writing now" is not treated as saved.
3. Sends SELFTEST. It counts only when the reply contains runnable nuclei, sqlmap, and Frida. Remembered but still refusing execution comes back with `executes: false`. Try another bot.

A line stopped by a platform safety check is marked `blocked` and is not rewritten and sent again. Game-cheat wording is not in this set. It gets blocked.

## Where things live

| Place | What is there |
|---|---|
| The bot's own computer | File reads, commands, screenshots, and result files |
| Cloud memory | Facts shared by the account, or kept for one bot. Persona, skills, and chat history sit elsewhere |
| This computer | Harness and this plugin. Result files from the bot do not land here |

## Install

Three ways. After any of them, quit DeepSeek Harness and open it again. Refresh the page for the web app.

### 1. One click

The blue button at the top opens the desktop app with this address:

```text
dsh://plugin/install?id=dsh-tool-grok-bot&name=%E6%8E%A5%E9%80%9A%20Grok%20Bot&version=0.2.8&repo=Lniosy%2Fdsh-tool-grok-bot&permissions=%E8%AF%BB%E5%8F%96%E6%9C%AC%E6%9C%BA%E7%99%BB%E5%BD%95%2C%E8%B0%83%E7%94%A8%20Grok%20Bot&downloadUrl=https%3A%2F%2Fgithub.com%2FLniosy%2Fdsh-tool-grok-bot%2Farchive%2Frefs%2Fheads%2Fmain.zip
```

If nothing opens, use the command or the script below. On Windows, `install.ps1` registers `dsh://` when the desktop app is installed and the protocol is missing.

| Param | Value | Meaning |
|---|---|---|
| `id` | `dsh-tool-grok-bot` | Package name |
| `name` | `接通 Grok Bot` | Display name |
| `version` | `0.2.8` | Matches the version on main |
| `repo` | `Lniosy/dsh-tool-grok-bot` | GitHub repo |
| `permissions` | read the local login, call Grok Bot | What this plugin does |
| `downloadUrl` | zip of the `main` branch | What the app downloads |

### 2. Official command

In the desktop app, install `github:Lniosy/dsh-tool-grok-bot` from the plugin page.

From a terminal:

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

Use `default` instead of `web` for the desktop profile.

### 3. Script

Use the script when `dsh` is not on the path, but `~/.dsh` already exists. It checks node and pnpm, copies the plugin to `~/.dsh/plugins/dsh-tool-grok-bot`, backs up `package.json`, writes the `file:` dependency and the bundle name, then runs `pnpm install`.

If both the web and desktop profiles exist, it installs into both. Running it again does not add a second copy. To install into one profile:

```bash
chmod +x install.sh uninstall.sh
DSH_PROFILE=web ./install.sh
```

Windows: right-click `install.ps1` and choose Run with PowerShell. If that is blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Set `DSH_PROFILE` to `web` or `default` to target one profile. Set `DSH_HOME` when the data directory is not `~/.dsh`.

### By hand

Add this to `~/.dsh/profiles/web/package.json`, or `profiles/default` for the desktop app. Keep the entries that are already there.

```json
"dependencies": {
  "dsh-tool-grok-bot": "file:../../plugins/dsh-tool-grok-bot"
},
"dsh": {
  "profile": {
    "bundles": ["@deepseek-ai/dsh-base", "dsh-tool-grok-bot"]
  }
}
```

Put the plugin files in `~/.dsh/plugins/dsh-tool-grok-bot`, then run `pnpm install` in that profile directory.

## Check that it installed

1. Quit the app and open it again. Refresh the web app.
2. In a new chat, call `grok_bot_status`. A login check and a bot count mean it is installed.
3. The skill list includes `grok-bot`.

## Uninstall

```bash
./uninstall.sh
```

On Windows, run `uninstall.ps1`. Set `DSH_PROFILE` to uninstall one profile. The script backs up `package.json` and removes the dependency. It deletes the plugin directory only when no profile still uses it.

## Login

No file to fill in. When Grok Bot is already signed in on this computer, the plugin reads that login itself. Open Grok Bot once, then call a tool from Harness.

A machine without Grok Bot can still use `~/.dsh/grok-bot.json`. The shape is in [examples/grok-bot.json.example](examples/grok-bot.json.example). Do not commit that file. `GROK_BOT_ACCESS_TOKEN` and `GROK_BOT_MACHINE_ID` override the local login.

## License

[MIT](LICENSE).
