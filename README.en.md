# dsh-tool-grok-bot

Send one message to a Grok Bot from [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) and read the reply.

[中文](README.md)

## Tools

| Tool | What it does |
|---|---|
| `grok_bot_list` | List bots. `kind: team` is a team room |
| `grok_bot_ask` | Ask one bot, or one team room |
| `grok_bot_ask_team` | Ask up to 8 bots the same text, separately |

The reply also shows up in that bot's official chat.

## Install

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

## Login

Put your own login in `DSH_HOME/grok-bot.json`. The shape is in [examples/grok-bot.json.example](examples/grok-bot.json.example). Do not commit that file, and do not paste it into an issue.

`GROK_BOT_ACCESS_TOKEN` and `GROK_BOT_MACHINE_ID` work as well.

## License

[MIT](LICENSE).
