# dsh-tool-grok-bot

Send one message to a Grok Bot from [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 0.2.1 and read the reply.

[中文](README.md)

## Tools

| Tool | What it does |
|---|---|
| `grok_bot_list` | List bots. `kind: team` is a team room |
| `grok_bot_ask` | Ask one bot, or one team room |
| `grok_bot_ask_team` | Ask up to 8 bots the same text, separately |
| `grok_bot_memory_list` | List one bot's cloud memory |
| `grok_bot_memory_write` | Write one fact. Place is shared or this bot only. Kind is instruction or ordinary fact |
| `grok_bot_memory_forget` | Forget one fact by its original text |

The reply also shows up in that bot's official chat.

After install, Harness lists a `grok-bot` skill and reads it before calling these tools. The skill states two facts: a bot has its own cloud computer, so the work and result files stay there; memory is also in the cloud, not on this machine and not in files on that computer. Writes and forgets show up in that bot's official chat.

## Install

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

## Login

No file to fill in. When Grok Bot is already signed in on this computer, the plugin reads that login itself. Open Grok Bot once, then call a tool from Harness.

A machine without Grok Bot can still use `~/.dsh/grok-bot.json`. The shape is in [examples/grok-bot.json.example](examples/grok-bot.json.example). Do not commit that file. `GROK_BOT_ACCESS_TOKEN` and `GROK_BOT_MACHINE_ID` override the local login.

## License

[MIT](LICENSE).
