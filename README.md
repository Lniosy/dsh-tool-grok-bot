# dsh-tool-grok-bot

在 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 0.2.1 里，把一句话发给指定的 Grok Bot，并取回回复。

[English](README.en.md)

## 工具

| 工具 | 作用 |
|---|---|
| `grok_bot_list` | 列出 Bot。`kind` 为 `team` 的是团队房间 |
| `grok_bot_ask` | 发给一个 Bot，或一个团队房间 |
| `grok_bot_ask_team` | 同一句话分别发给最多 8 个 Bot |

回复会出现在那个 Bot 的官方对话里。

## 安装

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

`dsh plugin` 会把它记进这个 profile 的插件层。

## 登录

把登录写到 `~/.dsh/grok-bot.json`。桌面版不另设目录时就读这里。格式见 [examples/grok-bot.json.example](examples/grok-bot.json.example)。这个文件不要提交，也不要发到 Issue 里。

也可以改用环境变量 `GROK_BOT_ACCESS_TOKEN` 和 `GROK_BOT_MACHINE_ID`。

## 许可

[MIT](LICENSE)。
