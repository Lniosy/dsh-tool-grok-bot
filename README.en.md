<p align="center">
  <img src="docs/logo.png" width="168" alt="DeepSeek Harness linked with Grok Bot">
</p>

<h1 align="center">Connect Grok Bot</h1>

<p align="center">
  Connect Grok Bot from DeepSeek Harness.<br>
  Send one line, read the reply, and manage cloud memory.
</p>

<p align="center">
  The whale is Harness. The two eyes are Grok Bot. Together they mean the two sides can talk.<br>
  <a href="README.md">中文</a>
  ·
  <a href="https://github.com/deepseek-ai/deepseek-harness">DeepSeek Harness 0.2.1</a>
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

Replies, writes, and forgets also show up in that bot's official chat.

After install, Harness lists a `grok-bot` skill and reads it before calling these tools. The skill states that a bot has its own cloud computer, so the work and result files stay there, and that memory is in the cloud too.

## Where things live

| Place | What is there |
|---|---|
| The bot's own computer | File reads, commands, screenshots, and result files |
| Cloud memory | Facts shared by the account, or kept for one bot. Persona, skills, and chat history sit elsewhere |
| This computer | Harness and this plugin. Result files from the bot do not land here |

## Install

In the desktop app, install `github:Lniosy/dsh-tool-grok-bot` from the plugin page, then quit and reopen the app.

For a command-line profile:

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

## Login

No file to fill in. When Grok Bot is already signed in on this computer, the plugin reads that login itself. Open Grok Bot once, then call a tool from Harness.

A machine without Grok Bot can still use `~/.dsh/grok-bot.json`. The shape is in [examples/grok-bot.json.example](examples/grok-bot.json.example). Do not commit that file. `GROK_BOT_ACCESS_TOKEN` and `GROK_BOT_MACHINE_ID` override the local login.

## License

[MIT](LICENSE).
